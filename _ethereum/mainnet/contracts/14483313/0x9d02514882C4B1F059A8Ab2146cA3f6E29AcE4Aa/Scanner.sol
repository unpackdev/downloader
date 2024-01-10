/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC721.sol";
import "Ownable.sol";
import "ISheetFighterToken.sol";
import "ICellToken.sol";
import "IPortal.sol";


/// @title Contract to send Sheet Fighters and $CELL between Ethereum and Polygon
/// @author Overlord Paper Co.
/// @notice A big thank you to 0xBasset from EtherOrcs! This contract is heavily influenced
/// @notice by the the EtherOrcs Ethereum <--> Polygon bridge, and 0xBasset was a great
/// @notice sounding board during development.
contract Scanner is Ownable {
    address public portal;
    address public sheetFighterToken;
    address public cellToken;
    mapping (address => address) public reflection;
    mapping (uint256 => address) public sheetOwner;

    constructor() Ownable() {}

    modifier onlyPortal() {
        require(portal != address(0), "Portal must be set");
        require(msg.sender == portal, "Only portal can do this");
        _;
    }


    /// @dev Initiatilize state for proxy contract
    /// @param portal_ Portal address
    /// @param sheetFighterToken_ SheetFighterToken address
    /// @param cellToken_ CellToken address
    function initialize(
        address portal_, 
        address sheetFighterToken_, 
        address cellToken_
    ) 
        external 
        onlyOwner
    {
        portal = portal_;
        sheetFighterToken = sheetFighterToken_;
        cellToken = cellToken_;
    }

    /// @dev Set Ethereum <--> Polygon reflection address
    /// @param key_ Address for contract on one network
    /// @param reflection_ Address for contract on sister network
    function setReflection(address key_, address reflection_) external onlyOwner {
        reflection[key_] = reflection_;
        reflection[reflection_] = key_;
    }

    /// @notice Bridge your Sheet Fighter(s) and $CELL between Ethereum and Polygon
    /// @notice This contract must be approved to transfer your Sheet Fighter(s) on your behalf
    /// @notice Sheet Fighter(s) must be in your wallet (i.e. not staked or bridged) to travel
    /// @param sheetFighterIds Ids of the Sheet Fighters being bridged
    /// @param cellAmount Amount of $CELL to bridge
    function travel(uint256[] calldata sheetFighterIds, uint256 cellAmount) external {
        require(sheetFighterIds.length > 0 || cellAmount > 0, "Can't bridge nothing");

        // Address of contract on the sister-chain
        address target = reflection[address(this)];

        uint256 numSheetFighters = sheetFighterIds.length;
        uint256 currIndex = 0;

        bytes[] memory calls = new bytes[]((numSheetFighters > 0 ? numSheetFighters + 1 : 0) + (cellAmount > 0 ? 1 : 0));

        // Handle Sheets
        if(numSheetFighters > 0 ) {
            // Transfer Sheets to bridge (SheetFighterToken contract then calls callback on this contract)
            _pullIds(sheetFighterToken, sheetFighterIds);

            // Recreate Sheets on sister-chain exact as they exist on this chain
            for(uint256 i = 0; i < numSheetFighters; i++) {
                calls[i] = _buildData(sheetFighterIds[i]);
            }

            calls[numSheetFighters] = abi.encodeWithSelector(this.unstakeMany.selector, reflection[sheetFighterToken], msg.sender, sheetFighterIds);

            currIndex += numSheetFighters + 1;
        }

        // Handle $CELL
        if(cellAmount > 0) {
            // Burn $CELL on this side of bridge
            ICellToken(cellToken).bridgeBurn(msg.sender, cellAmount);

            // Add call to mint $CELL on other side of bridge
            calls[currIndex] = abi.encodeWithSelector(this.mintCell.selector, reflection[cellToken], msg.sender, cellAmount);
        }

        // Send messages to portal
        IPortal(portal).sendMessage(abi.encode(target, calls));

    }

    /// @dev Callback function called by SheetFighterToken contract during travel
    /// @dev "Stakes" all Sheets being bridged to this contract (i.e. transfers custody to this contract)
    /// @param owner Address of the owner of the Sheet Fighters being bridged
    /// @param tokenIds Token ids of the Sheet Fighters being bridged
    function bridgeTokensCallback(address owner, uint256[] calldata tokenIds) external {
        require(msg.sender == sheetFighterToken, "Only SheetFighterToken contract can do this");

        for(uint256 i = 0; i < tokenIds.length; i++) {
            _stake(msg.sender, tokenIds[i], owner);
        }
    }

    /// @dev Unstake the Sheet Fighters from this contract and transfer ownership to owner
    /// @dev Called on the "to" network for bridging
    /// @param token Address of the ERC721 contract fot the tokens being bridged
    /// @param owner Address of the owner of the Sheet Fighters being bridged
    /// @param ids ERC721 token ids of the Sheet Fighters being bridged
    function unstakeMany(address token, address owner, uint256[] calldata ids) external onlyPortal {

        for (uint256 i = 0; i < ids.length; i++) {  
            delete sheetOwner[ids[i]];
            IERC721(token).transferFrom(address(this), owner, ids[i]);
        }
    }

    /// @dev Calls the SheetFighterToken contract with given calldata
    /// @dev This is used to execute the cross-chain function calls
    /// @param data Calldata with which to call SheetFighterToken
    function callSheets(bytes calldata data) external onlyPortal {
        (bool succ, ) = sheetFighterToken.call(data);
        require(succ);
    }

    /// @dev Mint $CELL on the "to" network
    /// @param token Address of CellToken contract
    /// @param to Address of user briding $CELL
    /// @param amount Amount of $CELL being bridged
    function mintCell(address token, address to, uint256 amount) external onlyPortal {
        ICellToken(token).bridgeMint(to, amount);
    }
    
    /// @dev Informs other contracts that this contract knows about ERC721s
    /// @dev Allows ERC721 safeTransfer and safeTransferFrom transactions to this contract
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @dev Call the bridgeSheets function on the "from" part of the network, which transfers tokens
    /// @param tokenAddress Address of SheetFighterToken contract
    /// @param tokenIds SheetFighterToken ids of Sheet Fighters being bridged
    function _pullIds(address tokenAddress, uint256[] calldata tokenIds) internal {
        // The ownership will be checked to the token contract
        ISheetFighterToken(tokenAddress).bridgeSheets(msg.sender, tokenIds);
    }

    /// @dev Set state variables mapping tokenId to owner
    /// @param token Address of ERC721 contract
    /// @param tokenId ERC721 id for token being staked
    /// @param owner Address of owner who is bridging
    function _stake(address token, uint256 tokenId, address owner) internal {
        require(sheetOwner[tokenId] == address(0), "Token already staked");
        require(msg.sender == token, "Not SF contract");
        require(IERC721(token).ownerOf(tokenId) == address(this), "Sheet not transferred");

        if (token == sheetFighterToken){ 
            sheetOwner[tokenId] = owner;
        }
    }

    /// @dev build calldata for transaction to update Sheet's stats
    /// @param id SheetFighterToken id
    function _buildData(uint256 id) internal view returns (bytes memory) {
        (uint8 hp, uint8 critical, uint8 heal, uint8 defense, uint8 attack, , ) = ISheetFighterToken(sheetFighterToken).tokenStats(id);
        bytes memory data = abi.encodeWithSelector(this.callSheets.selector, abi.encodeWithSelector(ISheetFighterToken.syncBridgedSheet.selector, id, hp, critical, heal, defense, attack));
        return data;
    }
}