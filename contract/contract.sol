// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IERC20Token {
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract Payroll {

    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    struct Employee {
        string name;
        uint age;
        uint salary;
        address employeeAddress;
    }

    Employee[] employees;

    function addEmployee(string memory name, uint age, uint salary, address employeeAddress) public {
        Employee memory newEmployee = Employee(name, age, salary, employeeAddress);
        employees.push(newEmployee);
    }
   


  function payEmployees(address employeeAddress, uint salary) public {
      IERC20Token cUsdToken = IERC20Token(cUsdTokenAddress);
        cUsdToken.approve(address(this), 100000000);

        bool success = cUsdToken.transferFrom(msg.sender, employeeAddress, salary);
        require(success, "Payment to employee failed");
    }

      function getEmployees() public view returns (Employee[] memory) {
        return employees;
    }

    function fireEmployee(address employeeAddress) public {
    // require(msg.sender == owner, "Only the owner can fire employees");
    uint indexToRemove = findEmployeeIndex(employeeAddress);
    require(indexToRemove < employees.length, "Employee not found");
    employees[indexToRemove] = employees[employees.length - 1];
    employees.pop();
}

function findEmployeeIndex(address employeeAddress) internal view returns (uint) {
    for (uint i = 0; i < employees.length; i++) {
        if (employees[i].employeeAddress == employeeAddress) {
            return i;
        }
    }
    return employees.length;
}

function updateSalary(address employeeAddress, uint newSalary) public {
    // require(msg.sender == owner, "Only the owner can update employee salary");
    uint indexToUpdate = findEmployeeIndex(employeeAddress);
    require(indexToUpdate < employees.length, "Employee not found");
    employees[indexToUpdate].salary = newSalary;
}


}


