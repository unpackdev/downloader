pragma solidity ^0.6.2;

import "./Ownable.sol";
import "./SafeMath.sol";

contract Package is Ownable {
    using SafeMath for uint256;

    function _decreaseAmountFee(uint256 _oldAmount) internal pure returns(uint256 _newAmount) {
        uint256 scaledFee = 2;
        uint256 scalledPercentage = 100;
        return _oldAmount.mul(scaledFee).div(scalledPercentage);
    }

    modifier canBuy(uint256 _idxPackage, uint256 _amount) {
        require(_idxPackage < availablePackage.length, "Index out of range");
        require(_amount > 0);
        require(availablePackage.length >= _idxPackage, "Package doesn't exists");
        require(availablePackage[_idxPackage].active, "Package is not active ");
        require(_amount.sub(_decreaseAmountFee(_amount)) > availablePackage[_idxPackage].minTokenAmount, "Amount is too small");
            _;
    }

    struct PackageItem {
        string  aliasName;
        uint256 daysLock;
        uint256 minTokenAmount;
        uint256 dailyPercentage;
        bool    active;
    }
    PackageItem[] public availablePackage;

    function showPackageDetail(uint16 _index) public view returns(string memory, uint256, uint256, uint256, bool) {
        require(_index < availablePackage.length, "Index out of range");
        return (
            availablePackage[_index].aliasName,
            availablePackage[_index].daysLock,
            availablePackage[_index].minTokenAmount,
            availablePackage[_index].dailyPercentage,
            availablePackage[_index].active
        );
    }

    function pushPackageDetail(
        string memory _aliasName,
        uint256 _daysLock,
        uint256 _minTokenAmount,
        uint256 _dailyPercentage
    ) public onlyOwner {
        PackageItem memory pkg = PackageItem({
            aliasName: _aliasName,
            daysLock: _daysLock,
            minTokenAmount: _minTokenAmount,
            dailyPercentage: _dailyPercentage,
            active: true
        });
        availablePackage.push(pkg);
    }

    function getLengthPackage() public view returns(uint256) {
        return availablePackage.length;
    }

    function _deltaTimestamp(uint256 _idxPackage) internal view returns(uint) {
        return availablePackage[_idxPackage].daysLock * 1 days + now;
    }

    function setActive(uint256 _idxPackage, bool _active) public onlyOwner {
        require(_idxPackage < availablePackage.length, "Index out of range");
        availablePackage[_idxPackage].active = _active;
    }

    function activePackage(uint _idxPackage) internal view returns(bool) {
        return availablePackage[_idxPackage].active;
    }
}
