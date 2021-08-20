// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//// binance 0xB99D36b6130767AfC57769cb81690E5049e38B3E
contract FeeManagerERC20 {

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  string private _name = "Full Bunny Dividends Token";
  string private _symbol = "FBDT";
  uint8 private _decimals = 9;

  // 1 Ether ~= $2000, 1 FBDT = $0.1 => 1 Ether ~= 20.000 FBDT
  // Hardcap ~= $120.000 ~= 60 Ethers ~= 1.200.000 FBDT
  // Half is ICO, half is dev, so _totalSupply = 2.400.000 FBDT
  uint256 private _totalSupply = 2400000 * (uint256(10) ** _decimals);

  uint256 public scaling = uint256(10) ** 8;
  mapping(address => uint256) public scaledDividendBalanceOf;
  uint256 public scaledDividendPerToken;
  mapping(address => uint256) public scaledDividendCreditedTo;
  uint256 public scaledRemainder = 0;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Withdrawn(address sender, uint256 amount);
  event Deposited(address sender, uint256 amount);

  constructor() {
    _balances[msg.sender] = _totalSupply;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function name() public view virtual returns (string memory) {
    return _name;
  }

  function symbol() public view virtual returns (string memory) {
    return _symbol;
  }

  function decimals() public view virtual returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view virtual returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view virtual returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public virtual returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view virtual returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    _approve(sender, _msgSender(), currentAllowance - amount);

    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    _approve(_msgSender(), spender, currentAllowance - subtractedValue);

    return true;
  }

  function deposit() public payable {
    // scale the deposit and add the previous remainder
    uint256 available = (msg.value * scaling) + scaledRemainder;
    scaledDividendPerToken += available / _totalSupply;
    // compute the new remainder
    scaledRemainder = available % _totalSupply;

    emit Deposited(msg.sender, msg.value);
  }

  function withdraw() public {
    update(msg.sender);
    uint256 amount = scaledDividendBalanceOf[msg.sender] / scaling;
    scaledDividendBalanceOf[msg.sender] %= scaling;  // retain the remainder
    payable(msg.sender).transfer(amount);

    emit Withdrawn(msg.sender, amount);
  }

  function update(address account) internal {
    uint256 owed = scaledDividendPerToken - scaledDividendCreditedTo[account];
    scaledDividendBalanceOf[account] += _balances[account] * owed;
    scaledDividendCreditedTo[account] = scaledDividendPerToken;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

    update(sender);
    update(recipient);

    _balances[sender] = senderBalance - amount;
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }

  receive() payable external {
    if (msg.value > 0) payable(msg.sender).transfer(msg.value);
  }

  fallback() payable external {
    if (msg.value > 0) payable(msg.sender).transfer(msg.value);
  }
}
