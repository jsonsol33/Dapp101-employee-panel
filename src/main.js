import Web3 from "web3"
import { newKitFromWeb3 } from "@celo/contractkit"
import marketplaceABI from "../contract/marketplace.abi.json"
import BigNumber from "bignumber.js"
import erc20 from "../contract/erc20.abi.json"



const crypto = require('crypto');

// Constants declaration
const ERC20_DECIMALS = 18
const MPContractAddress = "0x276C4CbD381B0b5B68DcCec37fCEA759e20e50E2"
const cUSDContractAddress = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1"



// Global variables
let kit; // celo kit instance
let contract; // contract instance

// Function to connect to the Celo wallet
const connectCeloWallet = async function () {
  if (window.celo) {
    notification("⚠️ Please approve this DApp to use it.")
    try {
      await window.celo.enable()
      notificationOff()

      const web3 = new Web3(window.celo)
      kit = newKitFromWeb3(web3)

      const accounts = await kit.web3.eth.getAccounts()
      kit.defaultAccount = accounts[0]

      contract = new kit.web3.eth.Contract(marketplaceABI, MPContractAddress)
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  } else {
    notification("⚠️ Please install the CeloExtensionWallet.")
  }
}

function notification(_text) {
document.querySelector(".alert").style.display = "block"
document.querySelector("#notification").textContent = _text
}


// Function to display notifications to the user
function notificationOff() {
document.querySelector(".alert").style.display = "none"
}

window.addEventListener("load", async () => {
  notification("⌛ Loading...")
await connectCeloWallet()
await getBalance()
await displayEmployees()
notificationOff()
});


async function approve(_amount) {
  const getCusdContract = new kit.web3.eth.Contract(erc20, cUSDContractAddress);
  const result = await getCusdContract.methods
      .approve(MPContractAddress, _amount)
      .send({ from: kit.defaultAccount });
  return result;
}



// Function to get the cUSD balance of the user's account and display it
 const getBalance = async function () {
 const totalBalance = await kit.getTotalBalance(kit.defaultAccount)
 const cUSDBalance = totalBalance.cUSD.shiftedBy(-ERC20_DECIMALS).toFixed(2)
 document.querySelector("#balance").textContent = cUSDBalance
 }

 const displayEmployees = async function() {
  if (contract) {
    // Clear the current employee list HTML elements
    const tableBody = document.querySelector("#employee-cards");
    tableBody.innerHTML = "";
    tableBody.className = "bg-white m-2 rounded-md";

    // Retrieve the updated employee list from the contract
    const employees = await contract.methods.getEmployees().call();

    // Create new HTML elements to display the updated employee list
    employees.forEach((employee) => {
      const row = document.createElement("tr");
      row.className = "w-44 space-between divide-y-2 divide-gray-200 text-sm "
      
      const nameCell = document.createElement("td");
      nameCell.className = "w-96 whitespace-nowrap px-4 py-2 font-medium text-gray-900";
      nameCell.innerHTML = employee.name;
      row.appendChild(nameCell);
      
      const ageCell = document.createElement("td");
      ageCell.className = "whitespace-nowrap px-4 py-2 text-gray-700";
      ageCell.innerHTML = employee.age;
      row.appendChild(ageCell);
      
      const salaryCell = document.createElement("td");
      salaryCell.className = "whitespace-nowrap px-4 py-2 text-gray-700";
      salaryCell.innerHTML = `${employee.salary}`;
      row.appendChild(salaryCell);

      const addressCel = document.createElement("td");
      addressCel.className = "whitespace-nowrap px-4 py-2 text-gray-700";
      addressCel.innerHTML = `${employee.employeeAddress}`;
      row.appendChild(addressCel);

      const viewButtonCell = document.createElement("td");
      viewButtonCell.className = "whitespace-nowrap px-4 py-2";
      viewButtonCell.id = "popupButton3"
      const viewButton = document.createElement("a");
      viewButton.className = "inline-block rounded bg-indigo-600 px-4 py-2 text-xs font-medium text-white hover:bg-indigo-700";
      viewButton.innerHTML = "Delete";
      viewButton.addEventListener("click", showPopup3); // Add event listener

      viewButtonCell.appendChild(viewButton);
      row.appendChild(viewButtonCell);

      tableBody.appendChild(row);
    });
  } else {
    console.log('Contract instance not initialized');
  }
};

window.onload = () => {
  displayEmployees();
};


 // When the user clicks the submit button, upload the file to the contract
document.querySelector("#submit").addEventListener('click', async () => {

  const accounts = await kit.web3.eth.getAccounts()
  kit.defaultAccount = accounts[0]

   // Get the file hash, name, description and location from the input fields
  const name = document.getElementById('name').value;
  const age = document.getElementById('age').value;
  const salary = document.getElementById('salary').value;
  const address = document.getElementById('address').value;

  // Check if all input fields are filled
if (!name || !age || !salary || !address) {
  notification('Please fill out all input fields');
  return;
}

  await contract.methods.addEmployee(name, age, salary, address)
  .send({ from: kit.defaultAccount });
  notification("Employee added");
  await contract.methods.getEmployees().call();

  displayEmployees();
})



// Pay an employee
 document.querySelector('#pay-submit').addEventListener('click', async () => {

  let employeeAddress = document.getElementById('address-employee').value;
  console.log(document.getElementById("address-employee").value);

  const  salary = new BigNumber(document.getElementById("amount").value);
  const  salaryShifted = salary.shiftedBy(ERC20_DECIMALS).toString();
  
   
  try{
    await approve(salaryShifted)
    await contract.methods.payEmployees(employeeAddress, salaryShifted).send({ from: kit.defaultAccount});
    notification(`Payment made`)

    } catch (error) {
        notification(`⚠️ ${error}.`)
        return;
    }
    getBalance()
    });

                             //  update salary

   document.querySelector('#update-salary').addEventListener('click', async () => {

  const employeeAddress = document.getElementById('employeeAddress').value;
  const newSalary = document.getElementById('newSalary').value;

  try{
    await contract.methods.updateSalary(employeeAddress, newSalary).send({ from:kit.defaultAccount });
    notification(`Salary updated`)
} catch (error) {
    notification(`⚠️ ${error}.`)
    return;
}
   displayEmployees()
  
 });

                            // delete employee

 document.querySelector('#fire-employee').addEventListener('click', async () => {
  const employeeAddress = document.getElementById('employeeAddress2').value;
  
  try{
    await contract.methods.fireEmployee(employeeAddress).send({ from: kit.defaultAccount });
    notification(`Employee fired`)
} catch (error) {
    notification(`⚠️ ${error}.`)
    return;
}    
  displayEmployees()
 });


var popup = document.getElementById("popup");
var overlay = document.getElementById("overlay");
var popupButton = document.getElementById("popupButton");
var closeButton = document.getElementById("closeButton");

function showPopup() {
	popup.style.display = "block";
	overlay.style.display = "block";
}

function hidePopup() {
	popup.style.display = "none";
	overlay.style.display = "none";
}

popupButton.addEventListener("click", showPopup);
closeButton.addEventListener("click", hidePopup);
overlay.addEventListener("click", hidePopup);


window.onclick = function(event) {
  if (event.target == overlay) {
    popup.style.display = "none";
    overlay.style.display = "none";
  }
}



var popup1 = document.getElementById("popup1");
var overlay1 = document.getElementById("overlay1");
var popupButton1 = document.getElementById("popupButton1");
var closeButton1 = document.getElementById("closeButton1");

function showPopup1() {
	popup1.style.display = "block";
	overlay1.style.display = "block";
}

function hidePopup1() {
	popup1.style.display = "none";
	overlay1.style.display = "none";
}

popupButton1.addEventListener("click", showPopup1);
closeButton1.addEventListener("click", hidePopup1);
overlay1.addEventListener("click", hidePopup1);


window.onclick = function(event) {
  if (event.target == overlay1) {
    popup1.style.display = "none";
    overlay1.style.display = "none";
  }
}


var popup2 = document.getElementById("popup2");
var overlay2 = document.getElementById("overlay2");
var popupButton2 = document.getElementById("popupButton2");
var closeButton2 = document.getElementById("closeButton2");

function showPopup2() {
	popup2.style.display = "block";
	overlay2.style.display = "block";
}

function hidePopup2() {
	popup2.style.display = "none";
	overlay2.style.display = "none";
}

popupButton2.addEventListener("click", showPopup2);
closeButton2.addEventListener("click", hidePopup2);
overlay2.addEventListener("click", hidePopup2);


window.onclick = function(event) {
  if (event.target == overlay2) {
    popup2.style.display = "none";
    overlay2.style.display = "none";
  }
}



var popup3 = document.getElementById("popup3");
var overlay3 = document.getElementById("overlay3");
var popupButton3 = document.getElementById("popupButton3");
var closeButton3 = document.getElementById("closeButton3");

function showPopup3() {
	popup3.style.display = "block";
	overlay3.style.display = "block";
}

function hidePopup3() {
	popup3.style.display = "none";
	overlay3.style.display = "none";
}

popupButton3.addEventListener("click", showPopup3);
closeButton3.addEventListener("click", hidePopup3);
overlay3.addEventListener("click", hidePopup3);


window.onclick = function(event) {
  if (event.target == overlay3) {
    popup3.style.display = "none";
    overlay3.style.display = "none";
  }
}