// SPDX-License-Identifier: MIT

pragma solidity =0.8.19;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract MakecoinServicesContract is Ownable {
    address payable public adminwallet;
    mapping(string => uint) public servicesFees;
    
    struct Account {
        address referrer;
        uint reward;
        uint referredCount;
    }

    struct ReferralHistory{
        address from;
        uint256 referralAmount;
        uint256 timestamp;
    }
    uint256 public levelRate = 1000;
    mapping(address => Account) public accounts;
    mapping(address =>  ReferralHistory[]) public userReferrals;

    event RegisteredReferer(address referee, address referrer);
    event RegisteredRefererFailed(address referee, address referrer, string reason);
    event PaidReferral(address from, address to, uint amount);
    event NewDeployed(uint cost,string servicename);

    constructor(address _adminwallet){
        adminwallet = payable(_adminwallet);
        servicesFees['basic'] = 34000000000000000;
        servicesFees['standard'] = 46000000000000000;
        servicesFees['premium'] = 63000000000000000;
    }

    function addServices(string memory _serviceName , uint _fees) public onlyOwner{
        servicesFees[_serviceName] = _fees;
    }

    function payServicesFees(string memory _serviceName , address _refaddress) payable public returns(bool){
        uint cost = servicesFees[_serviceName];
        require(cost > 0 , "Invalid request send");
        if(!hasReferrer(msg.sender)) {
            addReferrer(_refaddress);
        }
        payReferral(cost);
        adminwallet.transfer(address(this).balance);
        emit NewDeployed(cost,_serviceName);
        return true;
    }

    function setLevelRate(uint _rate) public onlyOwner{
        levelRate = _rate;
    }

    function hasReferrer(address addr) public view returns(bool){
        return accounts[addr].referrer != address(0);
    }

    function setAdminWallet(address _walletAddress) public onlyOwner{
        adminwallet = payable(_walletAddress);
    }

    function isCircularReference(address referrer, address referee) internal view returns(bool){
        address parent = referrer;

        for (uint i; i < 1; i++) {
            if (parent == address(0)) {
                break;
            }

            if (parent == referee) {
                return true;
            }

            parent = accounts[parent].referrer;
        }

        return false;
    }

    function addReferrer(address referrer) internal returns(bool){
        if (referrer == address(0)) {
            emit RegisteredRefererFailed(msg.sender, referrer, "Referrer cannot be 0x0 address");
            return false;
        } else if (isCircularReference(referrer, msg.sender)) {
            emit RegisteredRefererFailed(msg.sender, referrer, "Referee cannot be one of referrer uplines");
            return false;
        } else if (accounts[msg.sender].referrer != address(0)) {
            emit RegisteredRefererFailed(msg.sender, referrer, "Address have been registered upline");
            return false;
        }

        Account storage userAccount = accounts[msg.sender];
        Account storage parentAccount = accounts[referrer];
        userAccount.referrer = referrer;
        parentAccount.referredCount += 1;

        emit RegisteredReferer(msg.sender, referrer);
        return true;
    }
    
    function payReferral(uint256 value) internal{
        Account memory userAccount = accounts[msg.sender];
       
        address payable parent = payable(userAccount.referrer);
        Account storage parentAccount = accounts[userAccount.referrer];

        if (parent != address(0)) {
            uint c = (value * levelRate ) / 10000;
            parentAccount.reward += c;
            parent.transfer(c);
            
            emit PaidReferral(msg.sender, parent, c);
            userAccount = parentAccount;
        }
    }
}