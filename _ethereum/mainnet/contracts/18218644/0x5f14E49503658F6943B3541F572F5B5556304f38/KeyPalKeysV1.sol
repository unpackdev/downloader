// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    bool private _notEntered;

    constructor() {
        _notEntered = true;
    }

    modifier nonReentrant() {
        require(_notEntered, "ReentrancyGuard: Reentrant call");
        _notEntered = false;
        _;
        _notEntered = true;
    }
}

contract KeyPalKeysV1 is Ownable, ReentrancyGuard {
    address public protocolFeeDestination;
    uint256 public protocolFeePercent;
    uint256 public subjectFeePercent;

    mapping(address => uint256) public subjectPriceFactor;
    mapping(address => mapping(address => uint256)) public keysBalance;
    mapping(address => uint256) public keysSupply;

    event Trade(address trader, address subject, bool isBuy, uint256 keyAmount, uint256 ethAmount, uint256 protocolEthAmount, uint256 subjectEthAmount, uint256 supply);

    function setFeeDestination(address _feeDestination) public onlyOwner {
        protocolFeeDestination = _feeDestination;
    }

    function setProtocolFeePercent(uint256 _feePercent) public onlyOwner {
        require(_feePercent <= 0.02 ether, "Max fee is 2%");
        protocolFeePercent = _feePercent;
    }

    function setSubjectFeePercent(uint256 _feePercent) public onlyOwner {
        require(_feePercent <= 0.08 ether, "Max fee is 8%");
        subjectFeePercent = _feePercent;
    }

    // Function to set subject price factor
    function setSubjectPriceFactor(uint256 _priceFactor) public {
        // Check if the price factor is within the range [1000, 100000]
        require(_priceFactor >= 1000 && _priceFactor <= 100000, "Price factor must be between 1000 and 100000");

        // Check if the sender is the subject
        require(_msgSender() == msg.sender, "Only the subject can set their price factor");

        // Update the subject's price factor
        subjectPriceFactor[msg.sender] = _priceFactor;
    }


    function getCustomPrice(address keysSubject, uint256 amount) public view returns (uint256) {
        uint256 supply = keysSupply[keysSubject];
        uint256 priceFactor = subjectPriceFactor[keysSubject] > 0 ? subjectPriceFactor[keysSubject] : 16000;
        return getPrice(supply, amount, priceFactor);
    }

    function getPrice(uint256 supply, uint256 amount, uint256 priceFactor) public pure returns (uint256) {
        uint256 sum1 = supply == 0 ? 0 : (supply - 1) * supply * (2 * (supply - 1) + 1) / 6;
        uint256 sum2 = (supply + amount) * (supply + amount) * (2 * (supply + amount) + 1) / 6;
        return (sum2 - sum1) * 1 ether / priceFactor;
    }

    // Function to buy keys
    function buyKeys(address keysSubject, uint256 amount) public payable nonReentrant {
        uint256 supply = keysSupply[keysSubject];
        require(supply > 0 || keysSubject == msg.sender, "Only the keys' subject can buy the first key");
        
        uint256 price = getCustomPrice(keysSubject, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;

        require(msg.value >= price + protocolFee + subjectFee, "Insufficient payment");
        
        // Ensure enough funds in the contract before making transfers
        require(address(this).balance + msg.value >= price + protocolFee + subjectFee, "Not enough funds in the contract");

        keysBalance[keysSubject][msg.sender] += amount;
        keysSupply[keysSubject] += amount;

        emit Trade(msg.sender, keysSubject, true, amount, price, protocolFee, subjectFee, supply + amount);
        
        // Transfers
        (bool success1, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success2, ) = keysSubject.call{value: subjectFee}("");
        
        // Check each transfer
        require(success1, "Unable to send protocol fee");
        require(success2, "Unable to send subject fee");
    }

    // Function to sell keys
    function sellKeys(address keysSubject, uint256 amount) public payable nonReentrant {
        uint256 supply = keysSupply[keysSubject];
        require(supply > amount, "Cannot sell the last key");

        uint256 price = getCustomPrice(keysSubject, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;

        require(keysBalance[keysSubject][msg.sender] >= amount, "Insufficient keys");

        // Ensure enough funds in the contract before making transfers
        require(address(this).balance >= price, "Not enough funds in the contract");

        keysBalance[keysSubject][msg.sender] -= amount;
        keysSupply[keysSubject] -= amount;

        emit Trade(msg.sender, keysSubject, false, amount, price, protocolFee, subjectFee, supply - amount);

        // Transfers
        (bool success1, ) = msg.sender.call{value: price - protocolFee - subjectFee}("");
        (bool success2, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success3, ) = keysSubject.call{value: subjectFee}("");

        // Check each transfer
        require(success1, "Unable to send funds to msg.sender");
        require(success2, "Unable to send funds to protocolFeeDestination");
        require(success3, "Unable to send funds to keysSubject");
    }

}