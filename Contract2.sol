// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title Payroll Contract
 * @dev A smart contract for managing employee payroll using cUSD as the native token.
 */
contract Payroll {

    // Address of the cUSD token
    address private immutable _cUsdTokenAddress;

    // Employee data structure
    struct Employee {
        string name;
        uint256 age;
        uint256 salary;
        address employeeAddress;
    }

    // Array of employees
    Employee[] private _employees;

    /**
     * @dev Constructor to set the cUSD token address.
     * @param cUsdTokenAddress The address of the cUSD token.
     */
    constructor(address cUsdTokenAddress) {
        _cUsdTokenAddress = cUsdTokenAddress;
    }

    /**
     * @dev Adds a new employee to the contract.
     * @param name The name of the employee.
     * @param age The age of the employee.
     * @param salary The salary of the employee.
     * @param employeeAddress The address of the employee.
     */
    function addEmployee(string memory name, uint256 age, uint256 salary, address employeeAddress) public {
        Employee memory newEmployee = Employee(name, age, salary, employeeAddress);
        _employees.push(newEmployee);
    }

    /**
     * @dev Pays an employee their salary using cUSD tokens.
     * @param employeeAddress The address of the employee to pay.
     * @param salary The amount of salary to pay.
     */
    function payEmployee(address employeeAddress, uint256 salary) public {
        IERC20Token cUsdToken = IERC20Token(_cUsdTokenAddress);

        // Approve the transfer of cUSD tokens to this contract
        bool approved = cUsdToken.approve(address(this), salary);
        require(approved, "Failed to approve cUSD transfer");

        // Transfer the cUSD tokens from the sender to the employee
        bool success = cUsdToken.transferFrom(msg.sender, employeeAddress, salary);
        require(success, "Failed to transfer cUSD tokens to employee");
    }

    /**
     * @dev Returns an array of all employees in the contract.
     * @return Employee[] The array of employees.
     */
    function getEmployees() public view returns (Employee[] memory) {
        return _employees;
    }

    /**
     * @dev Removes an employee from the contract.
     * @param employeeAddress The address of the employee to remove.
     */
    function removeEmployee(address employeeAddress) public {
        uint256 indexToRemove = findEmployeeIndex(employeeAddress);
        require(indexToRemove < _employees.length, "Employee not found");

        // Replace the employee to remove with the last employee in the array and then remove the last employee
        _employees[indexToRemove] = _employees[_employees.length - 1];
        _employees.pop();
    }

    /**
     * @dev Finds the index of an employee in the array.
     * @param employeeAddress The address of the employee to find.
     * @return uint256 The index of the employee in the array.
     */
    function findEmployeeIndex(address employeeAddress) internal view returns (uint256) {
        for (uint256 i = 0; i < _employees.length; i++) {
            if (_employees[i].employeeAddress == employeeAddress) {
                return i;
            }
        }
        return _employees.length;
    }

    /**
     * @dev Updates the salary of an employee in the
