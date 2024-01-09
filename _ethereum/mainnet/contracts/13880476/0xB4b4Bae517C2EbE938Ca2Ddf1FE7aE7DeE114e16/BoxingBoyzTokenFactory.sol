// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721Enumerable.sol";

import "./IAuthenticator.sol";
import "./TokenRetriever.sol";
import "./IBoxingBoyzToken.sol";


/// @title BoxingBoyz Token Factory 
/// @dev Non-fungible token (ERC721) factory that mints BoxingBoyz tokens
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract BoxingBoyzTokenFactory is Ownable, TokenRetriever {

    enum Stages {
        Initializing,
        Deploying,
        Deployed
    }

    /**
     *  Storage
     */
    uint constant MAX_SUPPLY = 10_000;
    uint constant MAX_MINT_PER_CALL = 3;
    uint constant MAX_MINT_PER_ADDRESS = 3;
    uint constant MINT_FEE_PRIVATE = 0.2 ether;
    uint constant MINT_FEE_PUBLIC = 0.25 ether;
    uint constant PERCENTAGE_DENOMINATOR = 10_000;

    // Authentication
    address private whitelist;

    // Beneficiary
    address payable public beneficiary; 

    // Stakeholders
    mapping (address => uint) public stakeholders;
    address[] private stakeholdersIndex;

     // State
    uint public start;
    Stages public stage;
    address public token;
    bool public isPublic;

    /**
     * Modifiers
     */
    /// @dev Throw if at stage other than current stage
    /// @param _stage expected stage to test for
    modifier atStage(Stages _stage) {
        require(stage == _stage, "In wrong stage");
        _;
    }
    

    /// @dev Throw sender isn't a stakeholders
    modifier onlyStakeholders() {
        require(stakeholders[msg.sender] > 0, "Only stakeholders");
        _;
    }


    /**
     * Public Functions
     */
    /// @dev Start in the Initializing stage
    constructor() {
        stage = Stages.Initializing;
    }


    /// @dev Setup stakeholders
    /// @param _stakeholders The addresses of the stakeholders (first stakeholder is the beneficiary)
    /// @param _percentages The percentages of the stakeholders 
    function setupStakeholders(address payable[] calldata _stakeholders, uint[] calldata _percentages) public onlyOwner atStage(Stages.Initializing) {
        require(stakeholdersIndex.length == 0, "Stakeholders already setup");
        
        // First stakeholder is expected to be the beneficiary
        beneficiary = _stakeholders[0]; 

        uint total = 0;
        for (uint i = 0; i < _stakeholders.length; i++) {
            stakeholdersIndex.push(_stakeholders[i]);
            stakeholders[_stakeholders[i]] = _percentages[i];
            total += _percentages[i];
        }

        require(total == PERCENTAGE_DENOMINATOR, "Stakes should add up to 100%");
    }


    /// @dev Initialize the factory
    /// @param _start The timestamp of the start date
    /// @param _token The token that is minted
    /// @param _whitelist The address of the whitelist authenticator
    function initialize(uint _start, address _token, address _whitelist) public onlyOwner atStage(Stages.Initializing) {
        require(stakeholdersIndex.length > 0, "Setup stakeholders first");
        token = _token;
        start = _start;
        whitelist = _whitelist;
        isPublic = false;
        stage = Stages.Deploying;
    }


    /// @dev Premint for givaways etc
    /// @param _numberOfItemsToMint Number of items to mint
    /// @param _toAddress Receiving address
    function premint(uint _numberOfItemsToMint, address _toAddress) public onlyOwner atStage(Stages.Deploying) {
        for (uint i = 0; i < _numberOfItemsToMint; i++) {
            IBoxingBoyzToken(token).mintTo(_toAddress);
        }
    }


    /// @dev Deploy the contract (setup is final)
    function deploy() public onlyOwner atStage(Stages.Deploying) {
        stage = Stages.Deployed;
    }


    /// @dev Set contract URI
    /// @param _uri Location to contract info
    function setContractURI(string memory _uri) public onlyOwner {
        IBoxingBoyzToken(token).setContractURI(_uri);
    }


    /// @dev Set base token URI 
    /// @param _uri Base of location where token data is stored. To be postfixed with tokenId
    function setBaseTokenURI(string memory _uri) public onlyOwner {
        IBoxingBoyzToken(token).setBaseTokenURI(_uri);
    }


    /// @dev Starts the public sale - In the public sale the whitelist check is ommited and the public mint fee is used
    function makePublic() public onlyOwner {
        isPublic = true;
    }


    /// @dev Mint `_numberOfItemsToMint` items to to `_toAddress`
    /// @param _numberOfItemsToMint Number of items to mint
    /// @param _toAddress Address to mint to
    function mint(uint _numberOfItemsToMint, address _toAddress) public payable atStage(Stages.Deployed) {
        require(canMint(_numberOfItemsToMint), "Unable to mint items");
        require(_canPayMintFee(_numberOfItemsToMint, msg.value), "Unable to pay");

        if (_numberOfItemsToMint == 1) {
            IBoxingBoyzToken(token).mintTo(_toAddress);
        } else if (_numberOfItemsToMint > 1 && _numberOfItemsToMint <= MAX_MINT_PER_CALL) {
            for (uint i = 0; i < _numberOfItemsToMint; i++) {
                IBoxingBoyzToken(token).mintTo(_toAddress);
            }
        }
    }


    /// @dev Returns if it's still possible to mint `_numberOfItemsToMint`
    /// @param _numberOfItemsToMint Number of items to mint
    /// @return If the items can be minted
    function canMint(uint _numberOfItemsToMint) public view returns (bool) {
        
        // Enforce started rule
        if (block.timestamp < start){
            return false;
        }

        // Enforce max per call rule
        if (_numberOfItemsToMint > MAX_MINT_PER_CALL) {
            return false;
        }

        // Authenticate
        if (!isPublic && !IAuthenticator(whitelist).authenticate(msg.sender))
        {
            return false;
        }

        // Enforce max per address rule
        if ((IERC721Enumerable(token).balanceOf(msg.sender) + _numberOfItemsToMint) > MAX_MINT_PER_ADDRESS) {
            return false;
        }

        // Enforce max token rule
        return IERC721Enumerable(token).totalSupply() <= (MAX_SUPPLY - _numberOfItemsToMint);
    }


    /// @dev Returns true if the call has enough ether to pay the minting fee
    /// @param _numberOfItemsToMint Number of items to mint
    /// @return If the minting fee can be payed
    function canPayMintFee(uint _numberOfItemsToMint) public view returns (bool) {
        return _canPayMintFee(_numberOfItemsToMint, address(msg.sender).balance);
    }


    /// @dev Returns the ether amount needed to pay the minting fee
    /// @param _numberOfItemsToMint Number of items to mint
    /// @return Ether amount needed to pay the minting fee
    function getMintFee(uint _numberOfItemsToMint) public view returns (uint) {
        return _getMintFee(_numberOfItemsToMint);
    }


    /// @dev Allows the beneficiary to withdraw 
    function withdraw() public onlyStakeholders {
        uint balance = address(this).balance;
        for (uint i = 0; i < stakeholdersIndex.length; i++)
        {
            payable(stakeholdersIndex[i]).transfer(
                balance * stakeholders[stakeholdersIndex[i]] / PERCENTAGE_DENOMINATOR);
        }
    }


    /// @dev Failsafe mechanism
    /// Allows the owner to retrieve tokens from the contract that 
    /// might have been send there by accident
    /// @param _tokenContract The address of ERC20 compatible token
    function retrieveTokens(address _tokenContract) override public onlyOwner {
        super.retrieveTokens(_tokenContract);

        // Retrieve tokens from our token contract
        ITokenRetriever(address(token)).retrieveTokens(_tokenContract);
    }


    /// @dev Failsafe and clean-up mechanism
    /// Makes the token URI's perminant since the factory is it's only owner
    function destroy() public onlyOwner {
        selfdestruct(beneficiary);
    }


    /**
     * Internal Functions
     */
    /// @dev Returns if the call has enough ether to pay the minting fee
    /// @param _numberOfItemsToMint Number of items to mint
    /// @param _received The amount that was received
    /// @return If the minting fee can be payed
    function _canPayMintFee(uint _numberOfItemsToMint, uint _received) internal view returns (bool) {
        return _received >= _getMintFee(_numberOfItemsToMint);
    }


    /// @dev Returns the ether amount needed to pay the minting fee
    /// @param _numberOfItemsToMint Number of items to mint
    /// @return Ether amount needed to pay the minting fee
    function _getMintFee(uint _numberOfItemsToMint) internal view returns (uint) {
        return (isPublic ? MINT_FEE_PUBLIC : MINT_FEE_PRIVATE) * _numberOfItemsToMint;
    }
}