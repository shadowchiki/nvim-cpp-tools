#pragma once

#include <string>

namespace testing::name
{
class TestingClass
{
public:
    TestingClass();
    TestingClass(std::string value);
    virtual ~TestingClass() = default;

    virtual std::string virtualMethod() = 0;
    virtual int& method1(std::string value);

private:
    std::string value;
};
}  // namespace testing::name
