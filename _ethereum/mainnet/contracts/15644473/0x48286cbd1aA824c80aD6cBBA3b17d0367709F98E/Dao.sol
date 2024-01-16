// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";

import "./IERC721.sol";
import "./IERC1155.sol";

import "./AddressUpgradeable.sol";
import "./ERC1967Proxy.sol";

import "./BudgetApprovalExecutee.sol";

import "./IAdam.sol";
import "./IMembership.sol";
import "./IGovernFactory.sol";
import "./IMemberToken.sol";
import "./ITeam.sol";

import "./Concat.sol";
import "./InterfaceChecker.sol";

contract Dao is Initializable, UUPSUpgradeable, ERC721HolderUpgradeable, ERC1155HolderUpgradeable, BudgetApprovalExecutee {
    using Concat for string;
    using AddressUpgradeable for address;
    using InterfaceChecker for address;

    struct InitializeParams {
        address _creator;
        address _membership;
        address _liquidPool;
        address _governFactory;
        address _team;
        address _memberTokenImplementation;
        string _name;
        string _description;
        uint256 _locktime;
        uint256[4] generalGovernSetting;
        string[] tokenInfo;
        uint256 tokenAmount;
        DaoSetting daoSetting;
        address[] depositTokens;
        bool mintMemberToken;
        AdmissionToken[] admissionTokens;
        address baseCurrency;
        string logoCID;
    }

    struct AdmissionToken {
        address token;
        uint256 minTokenToAdmit;
        uint256 tokenId;
        bool isMemberToken;
    }

    struct AdmissionTokenSetting{
        uint256 minTokenToAdmit;
        uint256 tokenId;
        bool active;
    }

    struct DaoSetting {
        uint256 minDepositAmount;
    }

    enum VoteType {
        Membership,
        MemberToken,
        Other
    }


    address public memberToken;
    address public creator;
    address public adam;
    address public membership;
    address public liquidPool;
    address public governFactory;
    string public name;
    uint256 public locktime;
    uint256 public minDepositAmount;
    address public baseCurrency;
    string public logoCID;
    address[] public admissionTokens;
    
    mapping(address => uint256) public firstDepositTime;
    mapping(address => bool) public isAssetSupported;
    mapping(uint256 => bool) public teamWhitelist;
    mapping(address => AdmissionTokenSetting) public admissionTokenSetting;

    event AllowDepositToken(address token);
    event CreateMemberToken(address creator, address token);
    event SetFirstDepositTime(address owner, uint256 time);
    event WhitelistTeam(uint256 tokenId);
    event AddAdmissionToken(address token, uint256 minTokenToAdmit, uint256 tokenId, bool isMemberToken);
    event CreateMember(address account, uint256 depositAmount);
    event Deposit(address account, uint256 amount);
    event UpdateDaoSetting(uint256 minDepositAmount);
    event UpgradeDao(string remark);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
      _disableInitializers();
    }

    function initialize(InitializeParams calldata params) public initializer {
        require( 
            address(params._creator) != address(0)
            && address(params._membership) != address(0)
            && address(params._liquidPool) != address(0)
            && address(params._governFactory) != address(0)
            && address(params._team) != address(0)
            && address(params._memberTokenImplementation) != address(0)
            && address(params.baseCurrency) != address(0)
        , "Invaild Dao Setting");

        ___BudgetApprovalExecutee_init(params._team);

        adam = msg.sender;
        creator = params._creator;
        membership = params._membership;
        liquidPool = params._liquidPool;
        name = params._name;
        locktime = params._locktime;
        governFactory = params._governFactory;
        minDepositAmount = params.daoSetting.minDepositAmount;
        baseCurrency = params.baseCurrency;
        logoCID = params.logoCID;

        if (params.mintMemberToken) {
            // tokenInfo: [name, symbol]
            _createMemberToken(params._memberTokenImplementation, params.tokenInfo, params.tokenAmount);
        }

        _createGovern(
            "General",
            params.generalGovernSetting[0],
            params.generalGovernSetting[1],
            params.generalGovernSetting[2],
            params.generalGovernSetting[3]
        );

        _setAdmissionToken(params.admissionTokens);
        _mintMember(params._creator);
        _addAssets(params.depositTokens);

    }

    modifier onlyGovern(string memory category) {
        require(
            byPassGovern(msg.sender) || msg.sender == govern(category), "Action not permitted");
        _;
    }

    function setFirstDepositTime(address owner) public {
        require(msg.sender == liquidPool, "only LP");
        firstDepositTime[owner] = block.timestamp;
        emit SetFirstDepositTime(owner, block.timestamp);
    }

    function mintMemberToken(uint amount) public onlyGovern("General") {
        _mintMemberToken(amount);
    }

    function transferMemberToken(address to, uint amount) public onlyGovern("General") {
        _transferMemberToken(to, amount);
    }

    function _beforeCreateBudgetApproval(address budgetApproval) internal view override onlyGovern("General") {
        require(canCreateBudgetApproval(budgetApproval), "Budget Implementation not whitelisted");
    }

    function canCreateBudgetApproval(address budgetApproval) public view returns (bool) {
        return IAdam(adam).budgetApprovals(budgetApproval);
    }

    function govern(string memory gName) public view returns (address) {
        return IGovernFactory(governFactory).governMap(address(this), gName);
    }

    function byPassGovern(address account) public view returns (bool) {
        return (IMembership(membership).totalSupply() == 1 && isMember(account));
    }

    function isMember(address account) public view returns (bool) {
        return IMembership(membership).isMember(account);
    }

    function updateDaoSetting(DaoSetting calldata _setting) public onlyGovern("General") {
        minDepositAmount = _setting.minDepositAmount;
        emit UpdateDaoSetting(_setting.minDepositAmount);
    }

    function createGovern(
        string calldata _name,
        uint duration,
        uint quorum,
        uint passThreshold,
        uint voteToken
    ) public onlyGovern("General") {
        _createGovern(
            _name,
            duration,
            quorum,
            passThreshold,
            voteToken
        );
    }

    function getVoteTypeValues(VoteType voteType) internal view returns (address) {
        address _membership = membership;
        address _memberToken = memberToken;
        if (VoteType.Membership == voteType) {
            if (address(_membership) == address(0)) {
                revert("Membership not yet initialized");
            }
            return address(_membership);
        }

        if (VoteType.MemberToken == voteType) {
            if (address(_memberToken) == address(0)) {
                revert("MemberToken not yet initialized");
            }
            return address(_memberToken);
        }

        if (VoteType.Other == voteType) {
            // TODO: Other tokens e.g. outside ERC721 Votes
        }

        revert("Unsupported Token type");
    }

    function addAssets(address[] calldata erc20s) public onlyGovern("General") {
        _addAssets(erc20s);
    }
    function mintMember(address owner) public {
        require(msg.sender == liquidPool, "only LP");
        _mintMember(owner);
    }

    function createTeam(string memory title, address minter, address[] memory members, string memory description) public onlyGovern("General") {
      uint256 id = ITeam(team()).addTeam(title, minter, members, description);
      teamWhitelist[id] = true;

      emit WhitelistTeam(id);
    }

    function _createMemberToken(address memberTokenImplementation, string[] calldata tokenInfo, uint tokenAmount) internal {
        
        require(memberToken == address(0), "Member token already initialized");
        require(tokenInfo.length == 2, "Insufficient info to create member token");

        ERC1967Proxy _memberTokenContract = new ERC1967Proxy(memberTokenImplementation, "");
        address _memberToken = address(_memberTokenContract);
        memberToken = _memberToken;
        IMemberToken(_memberToken).initialize(address(this), tokenInfo[0], tokenInfo[1]);
        _addAsset(_memberToken);
        _mintMemberToken(tokenAmount);

        emit CreateMemberToken(msg.sender, _memberToken);
    }

    function _setAdmissionToken( AdmissionToken[] memory _admissionTokens) internal {
        address _memberToken = memberToken;

        require(_admissionTokens.length <= 3, "Admission Token length too long." );
        for(uint i = 0 ; i < _admissionTokens.length ; i++){
            address tokenAddress = _admissionTokens[i].isMemberToken ? _memberToken : _admissionTokens[i].token;
            
            require(admissionTokenSetting[tokenAddress].active == false, "Admission Token existed");      // not exist before 
            require(tokenAddress.isContract(), "Admission Token not Support!");

            admissionTokens.push(tokenAddress);
            admissionTokenSetting[tokenAddress] = AdmissionTokenSetting(
                _admissionTokens[i].minTokenToAdmit,
                _admissionTokens[i].tokenId,
                true
            );

            emit AddAdmissionToken(
                _admissionTokens[i].token, 
                _admissionTokens[i].minTokenToAdmit, 
                _admissionTokens[i].tokenId, 
                _admissionTokens[i].isMemberToken
            );
        }
    }

    function isPassAdmissionToken(address account) public view returns (bool){
        uint _admissionTokenLength = admissionTokens.length;
        for (uint i = 0; i < _admissionTokenLength; i++){
            address token = admissionTokens[i];
            uint256 _minTokenToAdmit = admissionTokenSetting[token].minTokenToAdmit;

            if(_minTokenToAdmit > 0 ){
                uint256 balance;
                if(token.isERC721()){
                    balance = IERC721(token).balanceOf(account);
                }else if(token.isERC1155()){
                    balance = IERC1155(token).balanceOf(account, admissionTokenSetting[token].tokenId);
                }else if(token.isERC20()){
                    balance = IERC20(token).balanceOf(account);
                }
                if(balance < _minTokenToAdmit){
                    return false;
                }
            }
        }
        return true;
    }

    function afterDeposit(address account, uint256 amount) public {
        if (firstDepositTime[account] == 0) {
            setFirstDepositTime(account);
            require(amount >= minDepositAmount, "deposit amount not enough");
            
            if (isMember(account)) {
                return;
            }
            require(isPassAdmissionToken(account), "Admission token not enough");
            mintMember(account);

            emit CreateMember(account, amount);
        }
    }

    function _createGovern(
        string memory _name,
        uint duration,
        uint quorum,
        uint passThreshold,
        uint voteToken
    ) internal {
        address _voteToken = getVoteTypeValues(VoteType(voteToken));
        IGovernFactory(governFactory).createGovern(
            _name,
            duration,
            quorum,
            passThreshold,
            _voteToken
        );
    }

    function _mintMemberToken(uint amount) internal {
        address _memberToken = memberToken;
        require(address(_memberToken) != address(0), "Member Token not Exist.");
        IMemberToken(address(_memberToken)).mint(address(this), amount);
    }
    function _transferMemberToken(address to, uint amount) internal {
        address _memberToken = memberToken;
        require(address(_memberToken) != address(0), "Member Token not Exist.");
        IMemberToken(address(_memberToken)).transfer(to, amount);
    }
    function _addAssets(address[] memory erc20s) internal {
        for (uint256 i = 0; i < erc20s.length; i++) {
            require(address(erc20s[i]) != address(0), "Not Supported ERC20 Token");
            _addAsset(erc20s[i]);
        }
    }
    function _addAsset(address erc20) internal {
        isAssetSupported[erc20] = true;
        emit AllowDepositToken(erc20);
    }
    function _mintMember(address owner) internal {
        IMembership(membership).createMember(owner);
    }

    function admissionTokensLength() external view returns(uint256) {
        return admissionTokens.length;
    }

    function _authorizeUpgrade(address) internal view override onlyGovern("General") {}

    function upgradeImplementations(address[] calldata targets, address[] calldata newImplementations, string memory remark) public onlyGovern("General") {
        require(targets.length == newImplementations.length, "params length not match");
        for (uint256 i = 0; i < targets.length; i++) {
            if (targets[i] == address(this)) {
                _upgradeTo(newImplementations[i]);
            } else {
                UUPSUpgradeable(targets[i]).upgradeTo(newImplementations[i]);
            }
        }

        emit UpgradeDao(remark);
    }


    receive() external payable {
      if (msg.sender != address(0) && msg.value != 0) {
        emit Deposit(msg.sender, msg.value);
      }
    }

    uint256[50] private __gap;
}