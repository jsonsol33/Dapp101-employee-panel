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
    address private _cUsdTokenAddress;
    address private _owner;
    mapping(address => Employee) private _employees;

    enum EmployeeStatus { Active, Inactive }

    struct Employee {
        string name;
        uint age;
        uint salary;
        EmployeeStatus status;
    }

    event EmployeeAdded(address indexed employeeAddress, string name, uint age, uint salary);
    event EmployeePaid(address indexed employeeAddress, uint amount);
    event EmployeeUpdated(address indexed employeeAddress, uint newSalary);
    event EmployeeRemoved(address indexed employeeAddress);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not authorized");
        _;
    }

    constructor(address cUsdTokenAddress) {
        _cUsdTokenAddress = cUsdTokenAddress;
        _owner = msg.sender;
    }

    function addEmployee(string memory name, uint age, uint salary, address employeeAddress) public onlyOwner {
        require(employeeAddress != address(0), "Invalid employee address");
        require(_employees[employeeAddress].age == 0, "Employee already exists");

        Employee memory newEmployee = Employee(name, age, salary, EmployeeStatus.Active);
        _employees[employeeAddress] = newEmployee;

        emit EmployeeAdded(employeeAddress, name, age, salary);
    }

    function payEmployees(address[] memory employeeAddresses, uint256[] memory salaries) public {
        IERC20Token cUsdToken = IERC20Token(_cUsdTokenAddress);
        uint256 totalAmount;

        // Calculate the total amount to pay all employees
        for (uint256 i = 0; i < employeeAddresses.length; i++) {
            require(_employees[employeeAddresses[i]].status == EmployeeStatus.Active, "Employee not active");
            totalAmount += salaries[i];
            require(totalAmount >= salaries[i], "Integer overflow");
        }

        // Approve the transfer of funds from the sender to the contract
        cUsdToken.approve(address(this), totalAmount);

        // Transfer funds to each employee
        for (uint256 i = 0; i < employeeAddresses.length; i++) {
            bool success = cUsdToken.transferFrom(msg.sender, employeeAddresses[i], salaries[i]);
            require(success, "Payment to employee failed");
            emit EmployeePaid(employeeAddresses[i], salaries[i]);
        }
    }

    function getEmployee(address employeeAddress) public view returns (string memory, uint, uint, EmployeeStatus) {
        Employee memory employee = _employees[employeeAddress];
        require(employee.age != 0, "Employee not found");
        return (employee.name, employee.age, employee.salary, employee.status);
    }

    function removeEmployee(address employeeAddress) public onlyOwner {
        Employee storage employee = _employees[employeeAddress];
        require(employee.age != 0, "Employee not found");

        employee.status = EmployeeStatus.Inactive;

        emit EmployeeRemoved(employeeAddress);
    }

    function updateSalary(address employeeAddress, uint newSalary) public onlyOwner {
        Employee storage employee = _employees[employeeAddress];
        require(employee.age != 0, "Employee not found");

        employee.salary = newSalary;

        emit EmployeeUpdated(employeeAddress, newSalary);
    }
}