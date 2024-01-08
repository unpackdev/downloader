// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Spacewalker.sol";

/**
 * @author Space Knight Club 
 * @title Proof of Knight - Non tradable NFT proving that you are part of the mysterious Space Knight Club. It's not about paying, it's about getting in
 */
contract ProofOfKnight is ERC721Enumerable, ERC721Burnable, Ownable {

    string private baseURI;
    
    address private spacewalkerContract;
    
    // Number of vouches received per address who wish to become Knight
    mapping(address => uint256) public numberOfVouchesReceived;
    
    // List of addresses vouched per Knight
    mapping (address => address[]) public addressesVouched;
    
    // Number of vouches given per Knight
    mapping(address => uint256) public numberOfVouchesGiven;
    
    // Next possible vouch per Knight
    mapping(address => uint256) public dateOfNextVouch;
    
    constructor(address _spacewalkerContract) ERC721("Proof of Knight", "POK") {
        spacewalkerContract = _spacewalkerContract;
    }
    
    /**
     * @notice vouch a Spacewalker in order to become a Knight and join the club 
     * @param spacewalkerAddr - the address owning the Spacewalker that will receive the vouch to become a Knight
     * @dev number of vouches needed to become a Knight depends on the number of Knights in the club. 
     * between 0 to 20 Knights - 3 Knights vouches are needed to become a Knight 
     * between 21 to 50 Knights - 4 Knights vouches are needed to become a Knight
     * between 51 to 100 Knights - 5 Knights vouches are needed to become a Knight
     * between 101 to 500 Knights - 6 Knights vouches are needed to become a Knight
     * between 501 to 1000 Knights - 7 Knights vouches are needed to become a Knight
     * after 1001 Knights - 8 Knights vouches are needed to become a Knight
     */
    function vouch(address spacewalkerAddr) public {
        Spacewalker sw = Spacewalker(spacewalkerContract);
        require(sw.eligibleToStandTrial(spacewalkerAddr), "Recipient must own at least one Spacewalker NFT that has served its locking period.");
        require(balanceOf(msg.sender) > 0, "Sender must be a Knight.");
        require(dateOfNextVouch[msg.sender] < block.timestamp, "Too soon for the Knight to vote.");
        require(balanceOf(spacewalkerAddr) == 0, "Recipient is already a Knight");
        address[] memory addressesVouchedBySender = addressesVouched[msg.sender];
        for (uint256 i; i < addressesVouchedBySender.length; i++) {
            require(addressesVouchedBySender[i] != spacewalkerAddr, "Knight cannot vouch two times the same Spacewalker.");
        }
        addressesVouched[msg.sender].push(spacewalkerAddr);
        numberOfVouchesGiven[msg.sender] +=1;
        numberOfVouchesReceived[spacewalkerAddr] += 1;
        dateOfNextVouch[msg.sender] = block.timestamp + 30 days;
        uint256 totalSupply = totalSupply();
        if (totalSupply < 21 && numberOfVouchesReceived[spacewalkerAddr] > 2) {
            _internalMint(spacewalkerAddr);
        }
        else if (totalSupply < 51 && numberOfVouchesReceived[spacewalkerAddr] > 3) {
            _internalMint(spacewalkerAddr);
        }
        else if (totalSupply < 101 && numberOfVouchesReceived[spacewalkerAddr] > 4) {
            _internalMint(spacewalkerAddr);
        }
        else if (totalSupply < 501 && numberOfVouchesReceived[spacewalkerAddr] > 5) {
            _internalMint(spacewalkerAddr);
        }
        else if (totalSupply < 1001 && numberOfVouchesReceived[spacewalkerAddr] > 6) {
            _internalMint(spacewalkerAddr);
        }
        else if (totalSupply > 1000 && numberOfVouchesReceived[spacewalkerAddr] > 7) {
            _internalMint(spacewalkerAddr);
        }
    }
    
    function getListOfaddressesVouched(address knight) public view returns(address[] memory) { 
        return addressesVouched[knight];   
    }
    
    /**
     * @dev Override transfers functions to prevent people from trading. Being a Knight has no price and cannot be transfered
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("Can't transfer Proof of Knight NFT");
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public pure override {
        revert("Can't transfer Proof of Knight NFT");
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("Can't transfer Proof of Knight NFT");
    }
    
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return baseURI;
    }
    
    /**
     * @notice minting function. Only available for admin of Knights, minting Proof of Knight after standing trial deliberations
     * @param recipient - the address who will receive the Proof of Knight NFT 
     */
    function mint(address recipient) public onlyOwner {
        _internalMint(recipient);
    }
    
    /**
     * @dev internal mint - two ways of minting a new Knight
     * 1 - be vouched by existing Knights to automatically be minted a POK
     * 2 - owner (DAO) mint a POK after standing trial 
     */
    function _internalMint(address recipient) internal {
        require(balanceOf(recipient) == 0, "Recipient can not already have a Proof of Knight");
        uint256 totalSupply = totalSupply();
        _safeMint(recipient, totalSupply);
    }
    
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        }

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
    
    /**
     * @notice Burn a POK - removing a Knight from the club. Being a Knight comes with responsabilities. 
     * @param tokenId - token ID of the POK to burn 
     * @dev can only be done by owner (DAO) after majority voting of the Knights.
     */
    function burn(uint256 tokenId) public override onlyOwner {
        _burn(tokenId);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
