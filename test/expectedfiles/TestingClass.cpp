#include "TestingClass.hpp"

namespace testing::name
{

TestingClass::TestingClass()
    : value()
{
}

TestingClass::TestingClass(std::string value)
    : value(value)
{
}

int& TestingClass::method1(std::string value)
{
}

}  // namespace testing::name
