#include <environment/HeightDeviationFeature.h>


namespace dwl
{

namespace environment
{

HeightDeviationFeature::HeightDeviationFeature() : space_discretization_(std::numeric_limits<double>::max(), std::numeric_limits<double>::max())
{
	name_ = "Height Deviation";

	average_area_.max_x = 0.1;
	average_area_.min_x = -0.1;
	average_area_.max_y = 0.1;
	average_area_.min_y = -0.1;
	average_area_.grid_resolution = 0.04;
}


HeightDeviationFeature::~HeightDeviationFeature()
{

}


void HeightDeviationFeature::computeReward(double& reward_value, Terrain terrain_info)
{
	// Setting the grid resolution of the gridmap
	space_discretization_.setEnvironmentResolution(terrain_info.resolution, true);

	// Getting the cell position
	Eigen::Vector3d cell_position = terrain_info.position;

	// Computing the average height of the neighboring area
	double height_average = 0, height_deviation = 0;
	int counter = 0;

	Eigen::Vector2d boundary_min, boundary_max;
	boundary_min(0) = average_area_.min_x + cell_position(0);
	boundary_min(1) = average_area_.min_y + cell_position(1);
	boundary_max(0) = average_area_.max_x + cell_position(0);
	boundary_max(1) = average_area_.max_y + cell_position(1);
	for (double y = boundary_min(1); y < boundary_max(1); y += average_area_.grid_resolution) {
		for (double x = boundary_min(0); x < boundary_max(0); x += average_area_.grid_resolution) {
			Eigen::Vector2d coord;
			coord(0) = x;
			coord(1) = y;
			Vertex vertex_2d;
			space_discretization_.coordToVertex(vertex_2d, coord);

			if (terrain_info.height_map.find(vertex_2d)->first == vertex_2d) {
				height_average += terrain_info.height_map.find(vertex_2d)->second;
				counter++;
			}
		}
	}
	if (counter != 0)
		height_average /= counter;

	// Computing the standard deviation of the height
	for (double y = boundary_min(1); y < boundary_max(1); y += average_area_.grid_resolution) {
		for (double x = boundary_min(0); x < boundary_max(0); x += average_area_.grid_resolution) {
			Eigen::Vector2d coord;
			coord(0) = x;
			coord(1) = y;
			Vertex vertex_2d;
			space_discretization_.coordToVertex(vertex_2d, coord);

			if (terrain_info.height_map.find(vertex_2d)->first == vertex_2d) {
				height_deviation += fabs(terrain_info.height_map.find(vertex_2d)->second - height_average);
			}
		}
	}

	reward_value = - height_deviation /counter;

	reward_value *= 50; /* heuristic value */
}

} //@namespace environment
} //@namespace dwl