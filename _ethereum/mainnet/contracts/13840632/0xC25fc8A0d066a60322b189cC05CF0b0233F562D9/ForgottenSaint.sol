// SPDX-License-Identifier: UNLICENSE

/*
    ______                       __  __                _____       _       __ 
   / ____/___  _________ _____  / /_/ /____  ____     / ___/____ _(_)___  / /_
  / /_  / __ \/ ___/ __ `/ __ \/ __/ __/ _ \/ __ \    \__ \/ __ `/ / __ \/ __/
 / __/ / /_/ / /  / /_/ / /_/ / /_/ /_/  __/ / / /   ___/ / /_/ / / / / / /_  
/_/    \____/_/   \__, /\____/\__/\__/\___/_/ /_/   /____/\__,_/_/_/ /_/\__/  
                 /____/                                                       
*/

/* "My favorite part of the holiday szn is blaming my long term regret not buying BAYC wen 0.2 floor price. Merry Xmas!" */

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract ForgottenSaint is ERC1155, Ownable {
    uint public MAX_SUPPLY = 1225; 
    uint public MAX_CLAIM_PER_TX = 12;

    uint private counter;

    // Charity address for the victims of 2021 Mt. Semeru Eruption (https://twitter.com/TheSaintNFT/status/1472327181254766599)
    address public constant charityAddress = 0x7DBEDdCbD9bD788a84Ad0C55E4b94Be0721A29b2;
    // Creator & Developer: (https://twitter.com/mfer8023)
    address public constant creatorAddress = 0xfa98aFe34D343D0e63C4C801EBce01d9D4459ECa;
       
    string _contractUri;

    bool public isMintActive = true;

    constructor (
        string memory _tokenURI,
        string memory __contractUri
    ) ERC1155(_tokenURI) {
        counter = 0;
        _contractUri = __contractUri;
    }

    function claim(uint amount) external payable {
        require(isMintActive, "Mint hasn't allowed yet.");
        require(amount > 0 && amount <= MAX_CLAIM_PER_TX, "Exceed min & max amount to claim.");
        require(counter + amount <= MAX_SUPPLY, "Exceed max supply.");
        require(msg.value >= 0, "Value can't be none. At least 0 (zero) eth.");
        
        mintBatch(msg.sender, amount);
    }

    // Inspired by DickleButts.sol
    function mintBatch(address to, uint amount) private {
        uint256[] memory ids = new uint256[](amount);
        uint256[] memory amounts = new uint256[](amount);
        uint c = 0;
        for(uint i = counter; i < counter + amount; i++) {
            ids[c] = i+1; // tokenID starts from 1 (one)
            amounts[c] = 1;
            c++;
        }
        counter += amount;
        _mintBatch(to, ids, amounts, "");
    }

    function give(address[] calldata recipient, uint[] calldata amount) external payable {
        require(isMintActive, "Mint hasn't allowed yet.");
        // Max recipient address in one txn is 5 (five)
        require(recipient.length > 0 && recipient.length <= 5, "Exceed min & max total recipient."); 
        require(amount.length > 0 && amount.length <= 5, "Exceed min & max total amount length.");
        require(recipient.length == amount.length, "Total recipient & amount do not match.");

        uint totalAmount = 0;
        for(uint i; i < amount.length; i++){
            totalAmount += amount[i];
        }
        require(counter + totalAmount <= MAX_SUPPLY, "Exceed max supply.");
        for(uint i; i < recipient.length; i++) {
            mintBatch(recipient[i], amount[i]);
        }
    }

    function contractURI() external view returns (string memory) {
        return _contractUri;
    }

    function totalSupply() external view returns (uint) {
        return counter;
    }

    function setContractURI(string memory __contractUri) external onlyOwner {
        _contractUri = __contractUri;
    }

    function setMaxSupply(uint _maxSupply) external onlyOwner {
        MAX_SUPPLY = _maxSupply;
    }

    function setTokenURI(string memory _uri) external onlyOwner {
        _setURI(_uri);
    }

    function toggleMintState() external onlyOwner {
        isMintActive = !isMintActive;
    }

    function withdrawAll() external onlyOwner {
        // 50% will goes to the victims of 2021 Mt. Semeru Eruption. Don't hesitate to put some of your ETH, we need your help.
        require(payable(charityAddress).send(address(this).balance * 1/2));
        require(payable(creatorAddress).send(address(this).balance));          
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(
            super.uri(_tokenId),
            "/",
            Strings.toString(_tokenId),
            ".json"
        ));
    }
}