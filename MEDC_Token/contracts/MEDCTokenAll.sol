pragma solidity ^0.4.20;

//standart library for uint
library SafeMath { 
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0){
        return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function pow(uint256 a, uint256 b) internal pure returns (uint256){ //power function
    if (b == 0){
      return 1;
    }
    uint256 c = a**b;
    assert (c >= a);
    return c;
  }
}

//standart contract to identify owner
contract Ownable {

  address public owner;

  address public newOwner;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function Ownable() public {
    owner = msg.sender;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    if (msg.sender == newOwner) {
      owner = newOwner;
    }
  }
}

contract MEDCToken is Ownable { //ERC - 20 token contract
  using SafeMath for uint;
  // Triggered when tokens are transferred.
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  // Triggered whenever approve(address _spender, uint256 _value) is called.
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  string public constant symbol = "MEDC";
  string public constant name = "MEDICULEUM"; //CHANGE IT
  uint8 public constant decimals = 18;
  uint256 _totalSupply = 42000000000 ether;

  // Balances for each account
  mapping(address => uint256) balances;

  // Owner of account approves the transfer of an amount to another account
  mapping(address => mapping (address => uint256)) allowed;

  function totalSupply() public view returns (uint256) { //standart ERC-20 function
    return _totalSupply;
  }

  function balanceOf(address _address) public view returns (uint256 balance) {//standart ERC-20 function
    return balances[_address];
  }
  
  //standart ERC-20 function
  function transfer(address _to, uint256 _amount) public returns (bool success) {
    require(this != _to);
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(msg.sender,_to,_amount);
    return true;
  }

  //standart ERC-20 function
  function transferFrom(address _from, address _to, uint256 _amount) public returns(bool success){
    require(this != _to);
    balances[_from] = balances[_from].sub(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(_from,_to,_amount);
    return true;
  }
  //standart ERC-20 function
  function approve(address _spender, uint256 _amount)public returns (bool success) { 
    allowed[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }

  //standart ERC-20 function
  function allowance(address _owner, address _spender)public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  //Constructor
  function MEDCToken() public {
    owner = msg.sender;
    balances[this] = _totalSupply;
  }

  address public crowdsaleContract;

  function setCrowdsaleContract (address _address) public{
    require(crowdsaleContract == address(0));

    crowdsaleContract = _address;
  }

  function sendCrowdsaleTokens (address _address, uint _value) public {
    require(msg.sender == crowdsaleContract);

    balances[this] = balances[this].sub(_value);
    balances[_address] = balances[_address].add(_value);
        
    emit Transfer(this,_address,_value);    
  }

  address distributionAddress = 0x925EcbBAd1dc1b46e9dA57827BD3BD2Aa20937e8;

  function endICO () public{
    require (msg.sender == crowdsaleContract);
    
    uint tokensSold = _totalSupply.sub(balances[this]);

    balances[distributionAddress] = balances[distributionAddress].add(tokensSold/50); //2%
    balances[address(this)] = balances[address(this)].sub(tokensSold/50);

    emit Transfer(address(this), distributionAddress, tokensSold/50);

    _totalSupply = _totalSupply.sub(balances[address(this)]);

    emit Transfer(this, 0, balances[this]);
    balances[address(this)] = 0;
  }
}