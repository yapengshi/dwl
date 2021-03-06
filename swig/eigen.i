/*
 */

%{
  #define SWIG_FILE_WITH_INIT
  #include "Eigen/Core"
  #include <vector>
  #include <map>
%}

%include "numpy.i"

%init
%{
  import_array();
%}


%fragment("Eigen_Fragments", "header",  fragment="NumPy_Fragments")
%{
  template <typename T> int NumPyType() {return -1;};

  template <class Derived>
  bool ConvertFromNumpyToEigenMatrix(Eigen::MatrixBase<Derived>* out, PyObject* in)
  {
    int rows = 0;
    int cols = 0;
    // Check object type
    if (!is_array(in))
    {
      PyErr_SetString(PyExc_ValueError, "The given input is not known as a NumPy array or matrix.");
      return false;
    }
    // Check data type
    else if (array_type(in) != NumPyType<typename Derived::Scalar>())
    {
      PyErr_SetString(PyExc_ValueError, "Type mismatch between NumPy and Eigen objects.");
      return false;
    }
    // Check dimensions
    else if (array_numdims(in) > 2)
    {
      PyErr_SetString(PyExc_ValueError, "Eigen only support 1D or 2D array.");
      return false;
    }
    else if (array_numdims(in) == 1)
    {
      rows = array_size(in,0);
      cols = 1;
      if ((Derived::RowsAtCompileTime != Eigen::Dynamic) && (Derived::RowsAtCompileTime != rows))
      {
        PyErr_SetString(PyExc_ValueError, "Row dimension mismatch between NumPy and Eigen objects (1D).");
        return false;
      }
      else if ((Derived::ColsAtCompileTime != Eigen::Dynamic) && (Derived::ColsAtCompileTime != 1))
      {
        PyErr_SetString(PyExc_ValueError, "Column dimension mismatch between NumPy and Eigen objects (1D).");
        return false;
      }
    }
    else if (array_numdims(in) == 2)
    {
      rows = array_size(in,0);
      cols = array_size(in,1);
      if ((Derived::RowsAtCompileTime != Eigen::Dynamic) && (Derived::RowsAtCompileTime != array_size(in,0)))
      {
        PyErr_SetString(PyExc_ValueError, "Row dimension mismatch between NumPy and Eigen objects (2D).");
        return false;
      }
      else if ((Derived::ColsAtCompileTime != Eigen::Dynamic) && (Derived::ColsAtCompileTime != array_size(in,1)))
      {
        PyErr_SetString(PyExc_ValueError, "Column dimension mismatch between NumPy and Eigen objects (2D).");
        return false;
      }
    }
    // Extract data
    int isNewObject = 0;
    PyArrayObject* temp = obj_to_array_contiguous_allow_conversion(in, array_type(in), &isNewObject);
    if (temp == NULL)
    {
      PyErr_SetString(PyExc_ValueError, "Impossible to convert the input into a Python array object.");
      return false;
    }
    out->derived().setZero(rows, cols);
    typename Derived::Scalar* data = static_cast<typename Derived::Scalar*>(PyArray_DATA(temp));
    for (int i = 0; i != rows; ++i)
      for (int j = 0; j != cols; ++j)
        out->coeffRef(i,j) = data[i*cols+j];

    return true;
  };

  // Copies values from Eigen type into an existing NumPy type
  template <class Derived>
  bool CopyFromEigenToNumPyMatrix(PyObject* out, Eigen::MatrixBase<Derived>* in)
  {
    int rows = 0;
    int cols = 0;
    // Check object type
    if (!is_array(out))
    {
      PyErr_SetString(PyExc_ValueError, "The given input is not known as a NumPy array or matrix.");
      return false;
    }
    // Check data type
    else if (array_type(out) != NumPyType<typename Derived::Scalar>())
    {
      PyErr_SetString(PyExc_ValueError, "Type mismatch between NumPy and Eigen objects.");
      return false;
    }
    // Check dimensions
    else if (array_numdims(out) > 2)
    {
      PyErr_SetString(PyExc_ValueError, "Eigen only support 1D or 2D array.");
      return false;
    }
    else if (array_numdims(out) == 1)
    {
      rows = array_size(out,0);
      cols = 1;
      if ((Derived::RowsAtCompileTime != Eigen::Dynamic) && (Derived::RowsAtCompileTime != rows))
      {
        PyErr_SetString(PyExc_ValueError, "Row dimension mismatch between NumPy and Eigen objects (1D).");
        return false;
      }
      else if ((Derived::ColsAtCompileTime != Eigen::Dynamic) && (Derived::ColsAtCompileTime != 1))
      {
        PyErr_SetString(PyExc_ValueError, "Column dimension mismatch between NumPy and Eigen objects (1D).");
        return false;
      }
    }
    else if (array_numdims(out) == 2)
    {
      rows = array_size(out,0);
      cols = array_size(out,1);
    }

    if (in->cols() != cols || in->rows() != rows) {
      /// TODO: be forgiving and simply create or resize the array
      PyErr_SetString(PyExc_ValueError, "Dimension mismatch between NumPy and Eigen object (return argument).");
      return false;
    }

    // Extract data
    int isNewObject = 0;
    PyArrayObject* temp = obj_to_array_contiguous_allow_conversion(out, array_type(out), &isNewObject);
    if (temp == NULL)
    {
      PyErr_SetString(PyExc_ValueError, "Impossible to convert the input into a Python array object.");
      return false;
    }

    typename Derived::Scalar* data = static_cast<typename Derived::Scalar*>(PyArray_DATA(temp));

    for (int i = 0; i != in->rows(); ++i) {
      for (int j = 0; j != in->cols(); ++j) {
        data[i*in->cols()+j] = in->coeff(i,j);
      }
    }

    return true;
  };

  template <class Derived>
  bool ConvertFromEigenToNumPyMatrix(PyObject** out, Eigen::MatrixBase<Derived>* in)
  {
    npy_intp dims[2] = {in->rows(), in->cols()};
    *out = PyArray_SimpleNew(2, dims, NumPyType<typename Derived::Scalar>());
    if (!out)
      return false;
    typename Derived::Scalar* data = static_cast<typename Derived::Scalar*>(PyArray_DATA((PyArrayObject*) *out));
    for (int i = 0; i != dims[0]; ++i)
      for (int j = 0; j != dims[1]; ++j)
        data[i*dims[1]+j] = in->coeff(i,j);
    return true;
  };

  template<> int NumPyType<double>() {return NPY_DOUBLE;};
  template<> int NumPyType<int>() {return NPY_INT;};
%}

// ----------------------------------------------------------------------------
// Macro to create the typemap for Eigen classes
// ----------------------------------------------------------------------------
%define %eigen_typemaps(CLASS...)

// In: (nothing: no constness)
%typemap(in, fragment="Eigen_Fragments") CLASS (CLASS temp)
{
  if (!ConvertFromNumpyToEigenMatrix<CLASS>(&temp, $input))
    SWIG_fail;
  $1 = temp;
}

// In: const&
%typemap(in, fragment="Eigen_Fragments") CLASS const& (CLASS temp)
{
  if (!ConvertFromNumpyToEigenMatrix<CLASS>(&temp, $input))
    SWIG_fail;
  $1 = &temp;
}

// In: MatrixBase const&
%typemap(in, fragment="Eigen_Fragments") Eigen::MatrixBase<CLASS> const& (CLASS temp)
{
  if (!ConvertFromNumpyToEigenMatrix<CLASS>(&temp, $input))
    SWIG_fail;
  $1 = &temp;
}

// In: & (not yet implemented)
%typemap(in, fragment="Eigen_Fragments") CLASS & (CLASS temp)
{
  if (!ConvertFromNumpyToEigenMatrix<CLASS>(&temp, $input))
    SWIG_fail;
  $1 = &temp;
}

// In: const* (not yet implemented)
%typemap(in, fragment="Eigen_Fragments") CLASS const*
{
  PyErr_SetString(PyExc_ValueError, "The input typemap for const pointer is not yet implemented. Please report this problem to the developer.");
  SWIG_fail;
}

// In: * (not yet implemented)
%typemap(in, fragment="Eigen_Fragments") CLASS *
{
  PyErr_SetString(PyExc_ValueError, "The input typemap for non-const pointer is not yet implemented. Please report this problem to the developer.");
  SWIG_fail;
}

// Out: (nothing: no constness)
%typemap(out, fragment="Eigen_Fragments") CLASS
{
  if (!ConvertFromEigenToNumPyMatrix<CLASS>(&$result, &$1))
    SWIG_fail;
}

// Out: const
%typemap(out, fragment="Eigen_Fragments") CLASS const
{
  if (!ConvertFromEigenToNumPyMatrix<CLASS>(&$result, &$1))
    SWIG_fail;
}

// Out: const&
%typemap(out, fragment="Eigen_Fragments") CLASS const&
{
  if (!ConvertFromEigenToNumPyMatrix<CLASS>(&$result, $1))
    SWIG_fail;
}

// Out: & (not yet implemented)
%typemap(out, fragment="Eigen_Fragments") CLASS &
{
  PyErr_SetString(PyExc_ValueError, "The output typemap for non-const reference is not yet implemented. Please report this problem to the developer.");
  SWIG_fail;
}

// Out: const* (not yet implemented)
%typemap(out, fragment="Eigen_Fragments") CLASS const*
{
  PyErr_SetString(PyExc_ValueError, "The output typemap for const pointer is not yet implemented. Please report this problem to the developer.");
  SWIG_fail;
}

// Out: * (not yet implemented)
%typemap(out, fragment="Eigen_Fragments") CLASS *
{
  PyErr_SetString(PyExc_ValueError, "The output typemap for non-const pointer is not yet implemented. Please report this problem to the developer.");
  SWIG_fail;
}

// Argout: const & (Disabled and prevents calling of the non-const typemap)
%typemap(argout, fragment="Eigen_Fragments") const CLASS & ""

// Argout: & (for returning values to in-out arguments)
%typemap(argout, fragment="Eigen_Fragments") CLASS &
{
  if (!CopyFromEigenToNumPyMatrix<CLASS>($input, $1))
    SWIG_fail;
}


// In: std::vector<>
%typemap(in, fragment="Eigen_Fragments") std::vector<CLASS> (std::vector<CLASS> temp)
{
  if (!PyList_Check($input))
    SWIG_fail;
  temp.resize(PyList_Size($input));
  for (size_t i = 0; i != PyList_Size($input); ++i) {
    if (!ConvertFromNumpyToEigenMatrix<CLASS>(&(temp[i]), PyList_GetItem($input, i)))
      SWIG_fail;
  }
  $1 = temp;
}

// In: const std::vector<>&
%typemap(in, fragment="Eigen_Fragments") std::vector<CLASS> const& (std::vector<CLASS> temp)
{
  if (!PyList_Check($input))
    SWIG_fail;
  temp.resize(PyList_Size($input));
  for (size_t i = 0; i != PyList_Size($input); ++i) {
    if (!ConvertFromNumpyToEigenMatrix<CLASS>(&(temp[i]), PyList_GetItem($input, i)))
      SWIG_fail;
  }
  $1 = temp;
}


// Out: std::vector<>
%typemap(out, fragment="Eigen_Fragments") std::vector<CLASS>
{
  $result = PyList_New($1.size());
  if (!$result)
    SWIG_fail;
  for (size_t i = 0; i != $1.size(); ++i) {
    PyObject *out;
    if (!ConvertFromEigenToNumPyMatrix(&out, &$1[i]))
      SWIG_fail;
    if (PyList_SetItem($result, i, out) == -1)
      SWIG_fail;
  }
}

// Out: const std::vector<>
%typemap(out, fragment="Eigen_Fragments") std::vector<CLASS> const
{
  $result = PyList_New($1.size());
  if (!$result)
    SWIG_fail;
  for (size_t i = 0; i != $1.size(); ++i) {
    PyObject *out;
    if (!ConvertFromEigenToNumPyMatrix(&out, &$1[i]))
      SWIG_fail;
    if (PyList_SetItem($result, i, out) == -1)
      SWIG_fail;
  }
}

// Out: const& std::vector<>
%typemap(out, fragment="Eigen_Fragments") std::vector<CLASS> const&
{
  $result = PyList_New($1.size());
  if (!$result)
    SWIG_fail;
  for (size_t i = 0; i != $1.size(); ++i) {
    PyObject *out;
    if (!ConvertFromEigenToNumPyMatrix(&out, &$1[i]))
      SWIG_fail;
    if (PyList_SetItem($result, i, out) == -1)
      SWIG_fail;
  }
}

// Out: & std::vector<> (not yet implemented)
%typemap(out, fragment="Eigen_Fragments") std::vector<CLASS> &
{
  PyErr_SetString(PyExc_ValueError, "The output typemap for non-const vector reference is not yet implemented. Please report this problem to the developer.");
  SWIG_fail;
}

// Out: const* std::vector<> (not yet implemented)
%typemap(out, fragment="Eigen_Fragments") CLASS const*
{
  PyErr_SetString(PyExc_ValueError, "The output typemap for const vector pointer is not yet implemented. Please report this problem to the developer.");
  SWIG_fail;
}

// Out: * std::vector<> (not yet implemented)
%typemap(out, fragment="Eigen_Fragments") CLASS *
{
  PyErr_SetString(PyExc_ValueError, "The output typemap for non-const vector pointer is not yet implemented. Please report this problem to the developer.");
  SWIG_fail;
}

// Argout: const std::vector<>& (Disabled and prevents calling of the non-const typemap)
%typemap(argout, fragment="Eigen_Fragments") const std::vector<CLASS> & ""

// Argout: std::vector<>& (for returning values to in-out arguments)
%typemap(argout, fragment="Eigen_Fragments") std::vector<CLASS> &
{
  $input = PyList_New($1->size());
  if (!$input)
    SWIG_fail;
  for (size_t i = 0; i != $1->size(); ++i) {
    PyObject *out;
    if (!ConvertFromEigenToNumPyMatrix(&out, &$1->at(i)))
      SWIG_fail;
    if (PyList_SetItem($input, i, out) == -1)
      SWIG_fail;
  }
}


// In: std::map<std::string,>
%typemap(in, fragment="Eigen_Fragments") std::map<std::string,CLASS> (std::map<std::string,CLASS> temp)
{
  if (!PyDict_Check($input))
    SWIG_fail;

  PyObject *key, *value;
  Py_ssize_t pos = 0;

  while (PyDict_Next($input, &pos, &key, &value)) {
	std::string tmp_key = PyString_AsString(key);
    CLASS tmp_value;
    if (!ConvertFromNumpyToEigenMatrix<CLASS>(&tmp_value, value))
      SWIG_fail;

    temp[tmp_key] = tmp_value;
  }
  $1 = temp;
}

// In: const std::map<std::string,>
%typemap(in, fragment="Eigen_Fragments") std::map<std::string,CLASS> const (std::map<std::string,CLASS> temp)
{
  if (!PyDict_Check($input))
    SWIG_fail;

  PyObject *key, *value;
  Py_ssize_t pos = 0;

  while (PyDict_Next($input, &pos, &key, &value)) {
	std::string tmp_key = PyString_AsString(key);
    CLASS tmp_value;
    if (!ConvertFromNumpyToEigenMatrix<CLASS>(&tmp_value, value))
      SWIG_fail;

    temp[tmp_key] = tmp_value;
  }
  $1 = temp;
}

// In: std::map<std::string,>&
%typemap(in, fragment="Eigen_Fragments") std::map<std::string,CLASS> & (std::map<std::string,CLASS> temp)
{
  if (!PyDict_Check($input))
    SWIG_fail;

  PyObject *key, *value;
  Py_ssize_t pos = 0;

  while (PyDict_Next($input, &pos, &key, &value)) {
	std::string tmp_key = PyString_AsString(key);
    CLASS tmp_value;
    if (!ConvertFromNumpyToEigenMatrix<CLASS>(&tmp_value, value))
      SWIG_fail;

    temp[tmp_key] = tmp_value;
  }
  $1 = &temp;
}

// In: const std::map<std::string,>&
%typemap(in, fragment="Eigen_Fragments") std::map<std::string,CLASS> const& (std::map<std::string,CLASS> temp)
{
  if (!PyDict_Check($input))
    SWIG_fail;

  PyObject *key, *value;
  Py_ssize_t pos = 0;

  while (PyDict_Next($input, &pos, &key, &value)) {
	std::string tmp_key = PyString_AsString(key);
    CLASS tmp_value;
    if (!ConvertFromNumpyToEigenMatrix<CLASS>(&tmp_value, value))
      SWIG_fail;

    temp[tmp_key] = tmp_value;
  }
  $1 = &temp;
}


// Out: std::map<std::string,>
%typemap(out, fragment="Eigen_Fragments") std::map<std::string,CLASS>
{
  $result = PyDict_New();
  const char* key;
  CLASS value;
  for (std::map<std::string,CLASS>::const_iterator it = $1.begin();
			it != $1.end(); ++it) {
    key = it->first.c_str();
    value = it->second;
    PyObject *out;
    if (!ConvertFromEigenToNumPyMatrix(&out, &value))
      SWIG_fail;
    if (PyDict_SetItem($result, PyString_FromString(key), out) == -1)
      SWIG_fail;
  }
}

// Out: const std::map<std::string,>
%typemap(out, fragment="Eigen_Fragments") std::map<std::string,CLASS> const
{
  $result = PyDict_New();
  const char* key;
  CLASS value;
  for (std::map<std::string,CLASS>::const_iterator it = $1.begin();
			it != $1.end(); ++it) {
    key = it->first.c_str();
    value = it->second;
    PyObject *out;
    if (!ConvertFromEigenToNumPyMatrix(&out, &value))
      SWIG_fail;
    if (PyDict_SetItem($result, PyString_FromString(key), out) == -1)
      SWIG_fail;
  }
}

// Out: const std::map<std::string,>&
%typemap(out, fragment="Eigen_Fragments") std::map<std::string,CLASS> const&
{
  $result = PyDict_New();
  const char* key;
  CLASS value;
  for (std::map<std::string,CLASS>::const_iterator it = $1->begin();
			it != $1->end(); ++it) {
    key = it->first.c_str();
    value = it->second;
    PyObject *out;
    if (!ConvertFromEigenToNumPyMatrix(&out, &value))
      SWIG_fail;
    if (PyDict_SetItem($result, PyString_FromString(key), out) == -1)
      SWIG_fail;
  }
}

// Out: std::map<std::string,>&
%typemap(out, fragment="Eigen_Fragments") std::map<std::string,CLASS> &
{
  $result = PyDict_New();
  const char* key;
  CLASS value;
  for (std::map<std::string,CLASS>::const_iterator it = $1->begin();
			it != $1->end(); ++it) {
    key = it->first.c_str();
    value = it->second;
    PyObject *out;
    if (!ConvertFromEigenToNumPyMatrix(&out, &value))
      SWIG_fail;
    if (PyDict_SetItem($result, PyString_FromString(key), out) == -1)
      SWIG_fail;
  }
}

// Out: const std::map<std::string,>*
%typemap(out, fragment="Eigen_Fragments") std::map<std::string,CLASS> const*
{
  $result = PyDict_New();
  const char* key;
  CLASS value;
  for (std::map<std::string,CLASS>::const_iterator it = $1->begin();
			it != $1->end(); ++it) {
    key = it->first.c_str();
    value = it->second;
    PyObject *out;
    if (!ConvertFromEigenToNumPyMatrix(&out, &value))
      SWIG_fail;
    if (PyDict_SetItem($result, PyString_FromString(key), out) == -1)
      SWIG_fail;
  }
}

// Out: std::map<std::string,>*
%typemap(out, fragment="Eigen_Fragments") std::map<std::string,CLASS> *
{
  $result = PyDict_New();
  const char* key;
  CLASS value;
  for (std::map<std::string,CLASS>::const_iterator it = $1->begin();
			it != $1->end(); ++it) {
    key = it->first.c_str();
    value = it->second;
    PyObject *out;
    if (!ConvertFromEigenToNumPyMatrix(&out, &value))
      SWIG_fail;
    if (PyDict_SetItem($result, PyString_FromString(key), out) == -1)
      SWIG_fail;
  }
}


// Argout: const std::map<std::string,>& (Disabled and prevents calling of the non-const typemap)
%typemap(argout, fragment="Eigen_Fragments") const std::map<std::string,CLASS> & ""

// Argout: std::map<std::string,>& (for returning values to in-out arguments)
%typemap(argout, fragment="Eigen_Fragments") std::map<std::string,CLASS> &
{
  const char* key;
  CLASS value;
  for (std::map<std::string,CLASS>::const_iterator it = $1->begin();
			it != $1->end(); ++it) {
	key = it->first.c_str();
    value = it->second;
    PyObject *out;
    if (!ConvertFromEigenToNumPyMatrix(&out, &value))
      SWIG_fail;
    if (PyDict_SetItem($input, PyString_FromString(key), out) == -1)
      SWIG_fail;
  }
}

// Argout: std::map<std::string,>* (for returning values to in-out arguments)
%typemap(argout, fragment="Eigen_Fragments") std::map<std::string,CLASS> *
{
  const char* key;
  CLASS value;
  for (std::map<std::string,CLASS>::const_iterator it = $1->begin();
			it != $1->end(); ++it) {
	key = it->first.c_str();
    value = it->second;
    PyObject *out;
    if (!ConvertFromEigenToNumPyMatrix(&out, &value))
      SWIG_fail;
    if (PyDict_SetItem($input, PyString_FromString(key), out) == -1)
      SWIG_fail;
  }
}


%typemap(in, fragment="Eigen_Fragments") const Eigen::Ref<const CLASS>& (CLASS temp)
{
  if (!ConvertFromNumpyToEigenMatrix<CLASS>(&temp, $input))
    SWIG_fail;
  Eigen::Ref<const CLASS > temp_ref(temp);
  $1 = &temp_ref;
}


%typecheck(SWIG_TYPECHECK_DOUBLE_ARRAY)
    CLASS,
    const CLASS &,
    CLASS const &,
    Eigen::MatrixBase<CLASS>,
    const Eigen::MatrixBase<CLASS> &,
    CLASS &
{
  $1 = is_array($input);
}

%typecheck(SWIG_TYPECHECK_DOUBLE_ARRAY)
    std::vector<CLASS>
{
  $1 = PyList_Check($input) && ((PyList_Size($input) == 0) || is_array(PyList_GetItem($input, 0)));
}

%typecheck(SWIG_TYPECHECK_DOUBLE_ARRAY)
    std::map<std::string,CLASS>
{
  $1 = PyDict_Check($input) && ((PyDict_Size($input) == 0) || is_array(PyDict_GetItem($input, 0)));
}

%enddef
