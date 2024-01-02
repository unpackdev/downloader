// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMintValidator.sol";
import "./CryptoNinjaChildrenSBT.sol";
import "./Ownable.sol";
import "./ICryptNinjaChildrenSbt.sol";
import "./AccessControl.sol";

contract CNCSBTMintCountValidator is CNCSBTIMintValidator, Ownable, AccessControl {
    struct PhaseData {
        uint32 totalSupply;
        uint128 sbtPrice;
        uint32 userMaxAmount;
    }
    uint256 public maxSupply = 555;
    mapping(uint256 => PhaseData) public phaseData;
    uint256 public phaseId = 2;
    ICryptNinjaChildrenSbt public cncSbt;
    address payable public withdrawAddress;

    mapping(uint256 => mapping (address => uint256)) public userMintedAmount;

    constructor(ICryptNinjaChildrenSbt _cncSbt) Ownable(msg.sender) {
        cncSbt = _cncSbt;
        setPhaseData(phaseId, 0, 0.01 ether, 3);
    }

    bytes32 public constant ADMIN = "ADMIN";

    modifier onlyAdmin() {
        require(hasRole(ADMIN, _msgSender()), 'Caller is not a admin');
        _;
    }

    function validate(uint256 _amount, uint256, uint256 _value, bytes32[] calldata) public onlyAdmin {
        _validate(_amount, _value, tx.origin);
    }

    function _validate(uint256 _amount, uint256 _value, address _to) internal {
        uint256 _phaseId = phaseId;
        uint32 amount = uint32(_amount);
        PhaseData storage _phaseData = phaseData[_phaseId];

        require(_amount > 0, "amount is zero");
        require(userMintedAmount[_phaseId][_to] + _amount <= _phaseData.userMaxAmount, "amount is over userMaxAmount");
        require(_value == _phaseData.sbtPrice * _amount, "value is not enough");
        require(maxSupply >= _phaseData.totalSupply + amount, "amount is over maxSupply");

        userMintedAmount[_phaseId][_to] += _amount;
        _phaseData.totalSupply += uint32(_amount);
    }

    bytes32 public constant PIEMENT = "PIEMENT";

    modifier onlyPiement() {
        require(hasRole(PIEMENT, _msgSender()), 'Caller is not a piement');
        _;
    }

    function mintPie(uint256 _amount, address _to) external payable onlyPiement {
        _validate(_amount, msg.value, _to);

        address[] memory toArr = new address[](1);
        toArr[0] = _to;
        uint256[] memory amountArr = new uint256[](1);
        amountArr[0] = _amount;

        cncSbt.adminMint(phaseId, toArr, amountArr);
    }

    function maxAmount() external view returns(uint256) {
        return uint256(phaseData[phaseId].userMaxAmount);
    }

    function getSbtPrice() external view returns(uint128) {
        return phaseData[phaseId].sbtPrice;
    }

    function getTotalSupply() external view returns(uint32) {
        return phaseData[phaseId].totalSupply;
    }

    function getUserMintedAmount(address _user) external view returns(uint256) {
        return userMintedAmount[phaseId][_user];
    }

    function setPhaseData(uint256 _phaseId, uint256 _totalSupply, uint256 _sbtPrice, uint256 _userMaxAmount) public onlyOwner {
        phaseData[_phaseId] = PhaseData(uint32(_totalSupply), uint128(_sbtPrice), uint32(_userMaxAmount));
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function grantRole(bytes32 role, address account) public virtual override onlyOwner {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override onlyOwner {
        _revokeRole(role, account);
    }

    function setPhaseId(uint256 _phaseId) public onlyOwner {
        phaseId = _phaseId;
    }

    function setWithdrawalAddress(address payable _withdrawalAddress) public onlyOwner {
        withdrawAddress = _withdrawalAddress;
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        withdrawAddress.transfer(balance);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl) returns (bool) {
        return
            AccessControl.supportsInterface(interfaceId) ||
            interfaceId == type(CNCSBTIMintValidator).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
