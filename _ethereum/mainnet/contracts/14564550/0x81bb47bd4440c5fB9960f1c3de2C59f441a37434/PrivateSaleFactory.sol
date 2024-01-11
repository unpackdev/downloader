// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Ownable.sol";
import "./Clones.sol";

import "./IPrivateSale.sol";

contract PrivateSaleFactory is Ownable {
    address public receiverAddress;
    address public devAddress;
    uint256 public devFee;

    address public implementation;

    mapping(string => IPrivateSale) public getPrivateSale;
    IPrivateSale[] public privateSales;

    event SaleCreated(
        IPrivateSale indexed privateSale,
        string indexed name,
        uint256 maxSupply,
        uint256 minAmount
    );
    event ImplementationSet(address indexed implementation);
    event ReceiverSet(address indexed receiver);
    event DevSet(address indexed devAddress);
    event DevFeeSet(uint256 devFee);
    event AddedToSale(string indexed name, address[] users);
    event RemovedFromSale(string indexed name, address[] users);
    event UserValidatedForSale(string indexed name, address[] users);

    constructor(address _receiverAddress, address _implementation) {
        require(_receiverAddress != address(0), "Factory: Receiver is 0");
        require(_implementation != address(0), "Factory: Implementation is 0");
        receiverAddress = _receiverAddress;
        devAddress = _msgSender();
        implementation = _implementation;

        devFee = 1_500;
        emit ReceiverSet(_receiverAddress);
        emit DevSet(_msgSender());
        emit DevFeeSet(devFee);
    }

    function lenPrivateSales() external view returns (uint256) {
        return privateSales.length;
    }

    function createPrivateSale(
        string calldata name,
        uint256 price,
        uint256 maxSupply,
        uint256 minAmount
    ) external onlyOwner returns (IPrivateSale) {
        require(
            getPrivateSale[name] == IPrivateSale(address(0)),
            "Factory: Sale already exists"
        );
        require(price > 0, "PrivateSale: Bad price");
        require(maxSupply > minAmount, "PrivateSale: Bad amounts");

        IPrivateSale privateSale = IPrivateSale(Clones.clone(implementation));

        getPrivateSale[name] = privateSale;
        privateSales.push(privateSale);

        IPrivateSale(privateSale).initialize(name, price, maxSupply, minAmount);

        emit SaleCreated(privateSale, name, maxSupply, minAmount);

        return privateSale;
    }

    function addToWhitelist(string calldata name, address[] calldata addresses)
        external
        onlyOwner
    {
        getPrivateSale[name].addToWhitelist(addresses);
        emit AddedToSale(name, addresses);
    }

    function removeFromWhitelist(
        string calldata name,
        address[] calldata addresses
    ) external onlyOwner {
        getPrivateSale[name].removeFromWhitelist(addresses);
        emit RemovedFromSale(name, addresses);
    }

    function validateUsers(string calldata name, address[] calldata addresses)
        external
        onlyOwner
    {
        getPrivateSale[name].validateUsers(addresses);
        emit UserValidatedForSale(name, addresses);
    }

    function claim(string calldata name) external onlyOwner {
        getPrivateSale[name].claim();
    }

    function endSale(string calldata name) external onlyOwner {
        getPrivateSale[name].endSale();
    }

    function setImplementation(address _implementation) external onlyOwner {
        require(_implementation != address(0), "Factory: implementation is 0");
        implementation = _implementation;
        emit ImplementationSet(_implementation);
    }

    function setReceiverAddress(address _receiverAddress) external onlyOwner {
        require(_receiverAddress != address(0), "Factory: Receiver is 0");
        receiverAddress = _receiverAddress;
        emit ReceiverSet(_receiverAddress);
    }

    function setDevAddress(address _devAddress) external onlyOwner {
        require(_devAddress != address(0), "Factory: Dev is 0");
        devAddress = _devAddress;
        emit DevSet(_devAddress);
    }

    function setDevFee(uint256 _devFee) external onlyOwner {
        require(_devFee <= 10_000, "Factory: Dev fee too big");
        require(_devFee >= 1_000, "Factory: Dev fee too low");
        devFee = _devFee;
        emit DevFeeSet(_devFee);
    }

    function emergencyWithdraw(string calldata name) external onlyOwner {
        getPrivateSale[name].emergencyWithdraw();
    }
}
