// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC721.sol";
import "./SafeMath.sol";
import "./Fork.sol";

/// @title  Mint and claim Fork after the Fork contract transfer ownership to this contract.
contract ForkFactory is Ownable {
    using SafeMath for uint256;

    IERC20 public fsmToken;
    Fork public fork;

    uint256 constant AMOUNT_OF_TOKEN_BURNED = 1720 * 1e18;
    mapping(uint256 => address) public idAddrMap;
    mapping(address => uint256) public addrIdMap;

    bool public mintFlag = false;               // Flag of phase ('false' means the start-up phase).
    uint256 public survivals = 86 * 1e18;       // transfer to savior
    uint256 public sacrifices =1634 * 1e18;     // stay in this contract
    address public savior = address(this);      // the Chosen One

    event Minted(address to, uint256 tokenId);
    event Claimed(address to, uint256 tokenId);
    event Survivals(uint256 survivals, uint256 sacrifices);
    event Savior(address to);

    constructor(address _fsmToken, address _fork) public {
        fsmToken = IERC20(_fsmToken);
        fork = Fork(_fork);
    }

    /**
    * @notice  Mint a Fork without FSMToken during the start-up phase.
    * @dev  This function will not be executed after using the startToMint() function.
    * @param to  Address of the owner of the Fork minted this time.
    * @param ipfsAddr  Address of the photo provided by the user.
    * @return  Token ID of this minting.
    */
    function mint0(address to, string memory ipfsAddr) 
        external
        onlyOwner
        returns (uint256)
    {
        require (mintFlag == false, "mint0: !Flag");
        require (addrIdMap[to] == 0, "mint0: $to");

        uint256 tokenId = fork.mint(address(this), ipfsAddr);

        idAddrMap[tokenId] = to;
        addrIdMap[to] = tokenId;
        
        emit Minted(address(this), tokenId);

        return tokenId;
    }

    /**
     * @notice  Batch mint Forks for some addresses and only once per address during the start-up phase.
     * @dev  If you need to send Fork to the same address multiple times, you can comment out some statements, as follows.
     */    
    function mint0Batch(address[] memory to, string[] memory ipfsAddr) 
        external
        onlyOwner
    {
        require (mintFlag == false, "mint0: !Flag");
        require (to.length == ipfsAddr.length);
        
        for (uint i = 0; i < to.length; i++) {
            if(addrIdMap[to[i]] != 0) continue;

            uint256 tokenId = fork.mint(address(this), ipfsAddr[i]);
            idAddrMap[tokenId] = to[i];
            addrIdMap[to[i]] = tokenId;
            emit Minted(address(this), tokenId);
        }
        return;     
    }
    
    /// @notice  Minting a Fork using 1720 FSMToken after the start-up phase. 
    function mint(string memory ipfsAddr) 
        external
        returns (uint256)
    {
        // require (fork.nextTokenId() > NUMBER_OF_GENESIS_FORK, "mint: !number");
        require (mintFlag == true, "mint: !Flag");

        uint256 bal = fsmToken.balanceOf(msg.sender);
        require (bal >= AMOUNT_OF_TOKEN_BURNED, "mint: !tokenBalance");
        // for the Chosen One
        fsmToken.transferFrom(
            msg.sender, 
            savior,
            survivals
        );
        // burn tokens by locked them into this contract
        fsmToken.transferFrom(
            msg.sender, 
            address(this),
            sacrifices
        );

        uint256 tokenId = fork.mint(msg.sender, ipfsAddr);

        emit Minted(msg.sender, tokenId);
    }

    /// @notice  View the ID of Fork that can be claimed by the address.
    function claimable(address alice) public view returns (uint256) 
    {
        return addrIdMap[alice];
    }

    /// @notice  Claim the Fork minted to the user in the start-up phase.
    function claim() external 
    {
        uint256 tokenId = addrIdMap[address(msg.sender)];
        require(tokenId != 0, "claim: no fork");

        idAddrMap[tokenId] = address(0);
        addrIdMap[address(msg.sender)] = 0;

        fork.safeTransferFrom(
            address(this), 
            address(msg.sender), 
            tokenId
        );

        emit Claimed(address(msg.sender), tokenId);
        return;
    }

    /// @notice  Finish the start-up phase and enter the coinage phase. This function can only be executed once and cannot be reversed
    function startToMint() external onlyOwner
    {
        require(mintFlag == false, "already mint");

        mintFlag = true;

        return;
    }
    /// @dev set ratio of 1720 FSM transferred to the savior
    function setSurvivals(uint256 ratio) external onlyOwner
    {
        require(ratio >= 0 && ratio <= 100);
        survivals = AMOUNT_OF_TOKEN_BURNED.mul(ratio).div(100);
        sacrifices = AMOUNT_OF_TOKEN_BURNED - survivals;
        emit Survivals(survivals,sacrifices);
        return;
    }
    /// @dev the Chosen One
    function setSavior(address _savior) external onlyOwner
    {
        savior = _savior;
        emit Savior(savior);
        return;
    }


}