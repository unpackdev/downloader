// contracts/GameItems.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract Jigsaw1BadgeContract is ERC1155, Ownable {
    string name;
    string symbol;
    using Counters for Counters.Counter;
    using Strings for uint256;
    uint256 public constant JIGSAW_FINAL_PICTURE = 1;
    //It tracks total tokens generated.
    Counters.Counter private totalSupply;

    //It tracks total token0 i.e. final nft picture generated.
    uint256 public totalToken0Minted = 0;

    //stores data for all players having minted final picture
    mapping( address => bool) public hasMintedFinalPicture;

    //can be owner or any contract or any address selected by owner.
    mapping( address => bool) isMinter;

    //finalPicture uri
    // string baseURI = "https://gateway.pinata.cloud/ipfs/QmcpGwJ9L1fRc6GhBxTXwd7nCr5YGxBpwQgjZWncs6JYZ1/{id}.json";
    string baseURI = "https://gateway.pinata.cloud/ipfs/QmV5jnuWmZUyNM25faA28wSXVxj6SMMYesRoUH98UghGSL/";

    constructor() ERC1155(baseURI) {
        name = "Jigsaw Final Picture";
        symbol = "JFP";
        addMinter(msg.sender);
        totalSupply.increment(); //already one tokenId generated.
    }

    /**
     * @dev Throws if called by any account other than the minter.
     */
    modifier onlyMinter() {
        require(isMinter[_msgSender()] == true, "ER: Caller is not the minter");
        _;
    }

    function mintFinalPicture(address _account) public onlyMinter{
        require(!hasMintedFinalPicture[_account], 'JBC: Final jigsaw puzzle picture already minted for this account');
        hasMintedFinalPicture[_account] = true;
        totalSupply.increment();
        totalToken0Minted += 1;
        _mint(_account, JIGSAW_FINAL_PICTURE, 1, '');
    }

    function bulkMintFinalPicture(address[] memory _accounts) public onlyMinter{
        for(uint256 i = 0; i < _accounts.length; i++){
            require(!hasMintedFinalPicture[_accounts[i]], 'JBC: Final jigsaw puzzle picture already minted for ');
            hasMintedFinalPicture[_accounts[i]] = true;
            totalSupply.increment();
            totalToken0Minted += 1;
            _mint(_accounts[i], JIGSAW_FINAL_PICTURE, 1, '');
        }
    }

    function addMinter( address _account) public onlyOwner{
        isMinter[_account] = true;
    }

    function removeMinter( address _account) public onlyOwner{
        isMinter[_account] = false;
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        if(tokenId <= totalToken0Minted)
            return string(
                    abi.encodePacked(baseURI, tokenId.toString(), '.json')
                );
        else return "ER: Invalid tokenId";
    }

    function setURI(string memory newuri) external {
        baseURI = newuri;
        _setURI(newuri);
    }

}