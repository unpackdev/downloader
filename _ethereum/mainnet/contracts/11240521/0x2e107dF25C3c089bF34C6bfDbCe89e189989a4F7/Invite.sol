pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./ERC721.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Address.sol";
import "./hotpotinterface.sol";
import "./ILoan.sol";
import "./IInvite.sol";
import "./Pausable.sol";

//1. generateCode()
//2. inputCode()
//3. calValidCode()
//4. validCode()
//5. calRatioUpdate()
contract Invite is Ownable, IInvite, Pausable {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public generateContract;
    address public validContract;
    uint256 internal lastCode = 1000;

    //100‰ = 10%
    uint256 constant MAX_RATIO_UPDATE = 100;

    //5‰
    uint256 public ratioUpdate = 5;

    //ratio increase at stage 2,  2‰
    uint256 public ratioUpdate2 = 2;

    uint256 constant public stage2Num = 50;

    ERC721 public erc721;

    event InviteCreated(address creator);
    event InviteInput(address user,uint256 code);
    event InviteValidate(address validator);

    struct InviteInfo {
        //The user who invites me
        address inviter;
        //My inviter's code
        uint256 inviteCode;

        bool validateInviter;
        //The invite code I create
        uint256 myInviteCode;
        //The user I invited
        EnumerableSet.AddressSet invites;
        //The validated user
        EnumerableSet.AddressSet validatedInvites;
        //The validated user at stage 2
        EnumerableSet.AddressSet validatedInvites2;
    }

    mapping(address => InviteInfo) internal inviteInfos;
    mapping(uint256 => address) internal codeCreators;

    uint256 internal randomSeed = 0;

    constructor(address _erc721) public {
        erc721 = ERC721(_erc721);
    }

    function setERC721(address _addr) external onlyOwner{
        require(_addr.isContract(),"This address is not contract!");
        erc721 = ERC721(_addr);
    }

    modifier checkCode(uint256 code) {
        require(codeCreators[code] != address(0), "Invalid invite code.");
        _;
    }

    function setValidContract(address _addr) external onlyOwner {
        require(_addr.isContract(),"This address is not contract!");
        validContract = _addr;
    }

    function setGenerateContract(address _addr) external onlyOwner {
        require(_addr.isContract(),"This address is not contract!");
        generateContract = _addr;
    }

    function setRatioUpdate(uint256 _ratio) external onlyOwner{
        ratioUpdate = _ratio;
    }

    function setRatioUpdate2(uint256 _ratio) external onlyOwner{
        ratioUpdate2 = _ratio;
    }

    function getInviteNum(address user) external view returns (uint256) {
        return inviteInfos[user].invites.length();
    }

    function getMyInviteCode(address user) external view returns(uint256){
        return inviteInfos[user].myInviteCode;
    }

    function calValidNum(address user)
        external
        override
        view
        returns (uint256)
    {
        return inviteInfos[user].validatedInvites.length();
    }

    function calValidNum2(address user)
        external
        override
        view
        returns (uint256)
    {
        return inviteInfos[user].validatedInvites2.length();
    }
    
    function calRatioUpdate(address user) external override view returns(uint256){
        uint256 total = this.calValidNum(user) * ratioUpdate;
        uint256 total2 = this.calValidNum2(user) * ratioUpdate2;
        total = total + total2;
        if(total>=MAX_RATIO_UPDATE){
            total = MAX_RATIO_UPDATE;
        }
        if(inviteInfos[user].validateInviter){
            total += 10;
        }
        return total;
    }

    function getInputInviteCode(address user) external view returns(uint256){
        return inviteInfos[user].inviteCode;
    }

    function checkValidated(address user) external view returns(bool){
        return inviteInfos[user].validateInviter;
    }

    function validCode(address user) external override whenNotPaused {
        require(
            msg.sender == validContract,
            "Only validContract can call this method"
        );
        address inviter = inviteInfos[user].inviter;
        if (inviter != address(0)&&!inviteInfos[user].validateInviter) {
            inviteInfos[user].validateInviter = true;
            if(erc721.totalSupply()<stage2Num){
                inviteInfos[inviter].validatedInvites.add(user);
            }else{
                inviteInfos[inviter].validatedInvites2.add(user);
            }
            emit InviteValidate(user);
        }
    }

    function generateCode(address user) external override whenNotPaused {
        require(
            msg.sender == generateContract,
            "Only generateContract can call this method"
        );
        if (inviteInfos[user].myInviteCode == 0) {
            randomSeed += 2;
            //generate random number
            //it is not that safe
            uint256 random = uint256(
                sha256(abi.encodePacked(now, randomSeed, user))
            ) % 20;

            uint256 code = lastCode + random;
            lastCode = code;

            inviteInfos[user].myInviteCode = code;

            codeCreators[code] = user;
            emit InviteCreated(user);
        }
    }

    function inputCode(uint256 code) external whenNotPaused checkCode(code) {
        require(
            inviteInfos[msg.sender].inviter == address(0),
            "You have invite code already."
        );

        address creator = codeCreators[code];
        require(creator != msg.sender, "This is your invite code.");
        inviteInfos[msg.sender].inviter = creator;
        inviteInfos[msg.sender].inviteCode = code;
        inviteInfos[creator].invites.add(msg.sender);
        emit InviteInput(msg.sender,code);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
