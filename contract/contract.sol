// SPDX-License-Identifier: GPL-3.0

/**
@title Payroll
@dev A smart contract for managing employee salaries using a cUSD token.
@author [Author Name]
@notice This contract allows the owner to add, pay, and update the salaries of employees.
@notice The owner can also fire employees.
*/
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
    /**
    @dev Address of the cUSD token contract
    */
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;
    /**
    @dev Owner of the contract
    */
    address internal owner;
    /**
    @dev Employee struct
    */
    struct Employee {
        string name;
        uint age;
        uint salary;
        address employeeAddress;
    }

    constructor() {
        owner = msg.sender;
    }
    /**
     * @dev Modifier to check if the caller is the owner of the contract.
     * @notice This modifier is used to restrict certain functions to the owner only.
     */
     modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }
    /**
    @dev List of employees
    */
    Employee[] employees;

    /**
    * @dev Add a new employee to the list.
    * @param name Name of the employee.
    * @param age Age of the employee.
    * @param salary Salary of the employee.
    * @param employeeAddress Ethereum address of the employee.
    * @notice This function adds a new employee to the list, but only if the employee does not already exist.
    * @notice Name, age, salary, and employee address must all be provided and meet certain criteria.
    */

    function addEmployee(string memory name, uint age, uint salary, address employeeAddress) public {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(age > 0, "Age must be greater than zero");
        require(salary > 0, "Salary must be greater than zero");
        require(employeeAddress != address(0), "Invalid employee address");
        // Check if employee already exists
        require(findEmployeeIndex(employeeAddress) == employees.length, "Employee already exists");
        Employee memory newEmployee = Employee(name, age, salary, employeeAddress);
        employees.push(newEmployee);
    }

    /**
     * @dev Pay an employee's salary in cUSD.
     * @param employeeAddress Ethereum address of the employee.
     * @param salary Amount of cUSD to pay the employee.
     * @notice This function transfers cUSD tokens from the contract owner to the employee.
     * @notice The amount of cUSD to pay must be greater than zero, and the employee address must be valid and associated with an existing employee.
     * @notice The contract owner must have approved the contract to spend the necessary amount of cUSD tokens.
     */
    function payEmployees(address employeeAddress, uint salary) public {
      require(employeeAddress != address(0), "Invalid employee address");
      require(salary > 0, "Invalid salary amount");
      IERC20Token cUsdToken = IERC20Token(cUsdTokenAddress);
      uint allowance = cUsdToken.allowance(msg.sender, address(this));
      require(allowance >= salary, "Insufficient allowance");

      uint indexToPay = findEmployeeIndex(employeeAddress);
    require(indexToPay < employees.length && employees[indexToPay].employeeAddress == employeeAddress, "Invalid employee address");

        bool success = cUsdToken.transferFrom(msg.sender, employeeAddress, salary);
        require(success, "Payment to employee failed");
    }

    /**
    @dev Returns a list of all employees
    @return List of all employees
    */
    function getEmployees() public view returns (Employee[] memory) {
        return employees;
    }

    /**
    @dev Fires an employee
    @param employeeAddress Address of the employee to be fired
    */
    function fireEmployee(address employeeAddress) public onlyOwner {
    require(employeeAddress != address(0), "Invalid employee address");
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

    /**
    @dev Allows the owner of the contract to update the salary of a specific employee.
    @param employeeAddress The address of the employee whose salary is being updated.
    @param newSalary The new salary to be updated for the employee.
    @notice No return value.
    */
    function updateSalary(address employeeAddress, uint newSalary) public onlyOwner {
        require(newSalary > 0, "Salary must be greater than 0");
        uint indexToUpdate = findEmployeeIndex(employeeAddress);
        require(indexToUpdate < employees.length && employees[indexToUpdate].employeeAddress == employeeAddress, "Employee not found/ Invalid empoyee address");
        employees[indexToUpdate].salary = newSalary;
    }

}

