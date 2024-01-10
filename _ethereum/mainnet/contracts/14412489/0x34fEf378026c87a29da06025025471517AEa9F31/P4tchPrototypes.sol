//
//                 01\0\1\0\1\1\1\0\1\0\0\0\1\0\10
//                 10/0/0/0/0/1/0/1/0/1/0/1/1/0/0/0/1
//                 10\0\1\1\0\1\0\0\1\0\0\0\0\1\1\0\0\00
//                                               10/1/1/1/0
//    0\1\1\0\1\0\0\1\1\1\1\0\1\1\0\0\1\1\0\01      1\0\0\1
//    1/0/0/1/1/0/1/0/0/1/0/1/1/0/0/0/1/1/0/11      0/1/0/0
//    1\0\1\1\0\0\0\0\1\0\1\1\0\1\1\0\0\0\1\10      1\1\0\0
//    0/1/1/1                                       1/0/0/1
//    0\1\0\0      00\1\0\0\1\1\0\0\1\0\1\0\1\1\0\0\1\0\1\0
//    1/1/0/1      11/0/0/1/0/1/0/1/1/1/0/1/1/0/1/1/1/1/0/1
//    1\1\0\1      10\0\1\1\0\0\1\0\1\0\1\1\0\1\1\1\0\0\1\0
//
//    0\1\0\0\1\0\1\1\0\1\1\1\0\0\1\1\1\0\1\00      0\1\1\0
//    1/1/1/1/0/1/0/1/0/1/0/0/0/1/1/0/1/0/0/00      1/1/0/0
//    1\0\1\0\1\0\0\0\1\1\0\0\1\1\0\0\0\0\1\01      1\0\0\0
//    1/0/0/1                                       1/1/0/0
//    1\0\0\1      10\1\0\0\1\0\1\1\0\0\0\1\1\0\1\0\0\1\1\1
//    1/0/1/1      00/1/1/0/0/1/0/1/0/1/0/0/0/1/1/0/1/0/0/0
//    0\1\1\0      01\0\1\0\1\0\0\1\1\0\1\0\1\1\0\0\1\0\1\0
//    1/1/1/0/10
//       00\1\1\0\0\0\0\1\0\1\1\1\0\1\1\0\0\11
//          0/0/1/0/1/0/1/1/1/0/0/1/0/0/1/1/10
//             01\1\0\1\1\0\0\1\0\1\0\0\0\0\00
//
//                   @author: Slaze x WEAV3
//                SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

contract P4tchPrototypes is ERC721, ERC721Enumerable, Ownable {

    uint256 public constant MAX_W_ID = 111;   //  111 [W] P4TCHs Total
    uint256 public constant MAX_X_ID = 444;   //  333 [X] P4TCHs Total
    uint256 public constant MAX_Y_ID = 1332;  //  888 [Y] P4TCHs Total
    uint256 public constant MAX_Z_ID = 3000;  // 1668 [Z] P4TCHs Total

    uint256 private _price = 0.111 ether;
    uint256 private nextPatchId = 1;
    uint256 private devMinted;

    bool public isWPublic;
    bool public isXPublic;
    bool public isYPublic;
    bool public isZPublic;
    bool public isWLActive;
    bool public isClaimActive;

    string public _baseTokenURI;

    mapping(address => bool) private whitelist;
    mapping(uint256 => uint256) private _claimed;

    constructor(string memory baseURI) ERC721("P4TCH [prototypes]", "WXYZ") {
        _baseTokenURI = baseURI;
    }

    /**
     * Whitelist Mint
     */
    function whitelistMint() external payable {
        require(isWLActive, "Whitelist sale must be active to mint tokens");
        require(isWhitelisted(msg.sender),"sender is NOT Whitelisted ");
        require(msg.value == _price, "Invalid Eth sent");
        uint256 _totalSupply = totalSupply();
        
        if (_totalSupply < MAX_W_ID) {         // [W]

        } else if (_totalSupply < MAX_X_ID) {  // [X]
            require(!isWPublic, "[W] is still active");

        } else if (_totalSupply < MAX_Y_ID) {  // [Y]
            require(!isXPublic, "[X] is still active");

        } else if (_totalSupply < MAX_Z_ID) {  // [Z]
            require(!isYPublic, "[Y] is still active");

        } else{
            revert SoldOut();
        }
        whitelist[msg.sender] = false;
        _safeMint(msg.sender, nextPatchId++);
    }

    /**
     * Public Mint
     */
    function publicMint(uint256 numOfPatches) external payable {
        require(numOfPatches > 0, "Must mint at least one");
        require(!isWLActive, "Cant mint during whitelist sale");
        require(msg.value == _price * numOfPatches, "Invalid Eth sent");
        uint256 _newSupply = totalSupply() + numOfPatches;

        if (_newSupply <= MAX_W_ID) {                   // [W]
            require(isWPublic, "[W] public sale must be active to mint");
            require(numOfPatches <= 2, "Only up to 2 [W] can be minted at once");

        } else if (_newSupply <= MAX_X_ID) {            // [X]
            require(isXPublic, "[X] public sale must be active to mint");
            require(numOfPatches <= 3, "Only up to 3 [X] can be minted at once");

        } else if (_newSupply <= MAX_Y_ID) {            // [Y]
            require(isYPublic, "[Y] public sale must be active to mint");
            require(numOfPatches <= 4, "Only up to 4 [Y] can be minted at once");

        } else if (_newSupply <= MAX_Z_ID) {            // [Z]
            require(isZPublic, "[Z] public sale must be active to mint");
            require(numOfPatches <= 5, "Only up to 5 [Z] can be minted at once");

        } else {
            revert SoldOut();
        }
        for (uint256 i = 0; i < numOfPatches; i++) {
            _safeMint(msg.sender, nextPatchId++);
        }
    }

    /**
     * P4TCH Holder Mint
     */
    function claimMint(uint256 _tokenId) external payable {
        require(isClaimActive, "Claim is not active");
        require(ownerOf(_tokenId) == msg.sender, "owner of token only");
        require(msg.value == _price, "Invalid Eth sent");
        uint256 _totalSupply = totalSupply();

/* W */ if (_tokenId <= 111) {                 // 1[X], 2[Y], 3[Z] Claimable

            if (_totalSupply < MAX_X_ID) {

                require(!isClaimed(_tokenId + 10000), "1[X] has already been claimed");
                _setClaimed(_tokenId + 10000);

            } else if (_totalSupply < MAX_Y_ID) {

                if (!isClaimed(_tokenId + 20000)) {        // 1st [Y] claim
                    _setClaimed(_tokenId + 20000);
                } else if (!isClaimed(_tokenId + 30000)) { // 2nd [Y] claim
                    _setClaimed(_tokenId + 30000);
                } else {
                    revert MaxAllowed();
                }
            } else if (_totalSupply < MAX_Z_ID) {

                if (!isClaimed(_tokenId + 40000)) {        // 1st [Z] claim
                    _setClaimed(_tokenId + 40000);
                } else if (!isClaimed(_tokenId + 50000)) { // 2nd [Z] claim
                    _setClaimed(_tokenId + 50000);
                } else if (!isClaimed(_tokenId + 60000)) { // 3rd [Z] claim
                    _setClaimed(_tokenId + 60000);
                } else {
                    revert MaxAllowed();
                }
            } else {
                revert SoldOut();
            }
/* X */ } else if (_tokenId - MAX_W_ID <= 333) {    // 1[Y], 1[Z] Claimable

            if (_totalSupply < MAX_Y_ID) {
                require(!isClaimed(_tokenId + 70000), "1[Y] has already been claimed");
                _setClaimed(_tokenId + 70000);

            } else if (_totalSupply < MAX_Z_ID) {
                require(!isClaimed(_tokenId + 80000), "1[Z] has already been claimed");
                _setClaimed(_tokenId + 80000);

            } else {
                revert SoldOut();
            }
/* Y */ } else if (_tokenId - MAX_X_ID <= 888) {         // 1[Z] Claimable
            require(_totalSupply < MAX_Z_ID);
            require(!isClaimed(_tokenId + 90000), "1[Z] has already been claimed");
            _setClaimed(_tokenId + 90000);

        } else {
            revert SoldOut();
        }
        _safeMint(msg.sender, nextPatchId++);
    }

    /**
     * Dev Mint
     */
    function devMint(uint256 numOfPatches) external onlyOwner {
        require(numOfPatches > 0, "Must mint at least one");
        uint256 _newSupply = totalSupply() + numOfPatches;
        uint256 _totalSupply = totalSupply();

        if (_newSupply <= MAX_W_ID) {                    // [W]
            require(devMinted + numOfPatches <= 11, "Dev minted 11 [W] already");

        } else if (_newSupply <= MAX_X_ID) {             // [X]
            require(_totalSupply >= MAX_W_ID, "The last W ID has not been minted yet");
            require(devMinted + numOfPatches <= 44, "Dev minted 33 [X] already");

        } else if (_newSupply <= MAX_Y_ID) {             // [Y]
            require(_totalSupply >= MAX_X_ID, "The last X ID has not been minted yet");
            require(devMinted + numOfPatches <= 132, "Dev minted 88 [Y] already");

        } else if (_newSupply <= MAX_Z_ID) {             // [Z]
            require(_totalSupply >= MAX_Y_ID, "The last Y ID has not been minted yet");
            require(devMinted + numOfPatches <= 300, "Dev minted 168 [Z] already");

        } else {
            revert MaxAllowed();
        }
        devMinted += numOfPatches;
        for (uint256 i = 0; i < numOfPatches; i++) {
            _safeMint(msg.sender, nextPatchId++);
        }
    }

    /**
     * Whitelist Functions
     */
    function addWL(address _address) public onlyOwner {
        whitelist[_address] = true;
    }

    function removeWL(address _address) public onlyOwner {
        whitelist[_address] = false;
    }

    function addWLAddresses(address[] memory _address) external onlyOwner {
        for (uint i = 0; i < _address.length; i++) {
            addWL(_address[i]);
        }
    }

    function removeWLAddresses(address[] memory _address) external onlyOwner {
        for (uint i = 0; i < _address.length; i++) {
            removeWL(_address[i]);
        }
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        _price = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    /**
     * Claimed Functions
     */
    function isClaimed(uint256 _tokenId) public view returns (bool) {
        uint256 wordIndex = _tokenId / 256;
        uint256 bitIndex = _tokenId % 256;
        uint256 mask = 1 << bitIndex;
        return _claimed[wordIndex] & mask == mask;
    }

    function _setClaimed(uint256 _tokenId) internal{
        uint256 wordIndex = _tokenId / 256;
        uint256 bitIndex = _tokenId % 256;
        uint256 mask = 1 << bitIndex;
        _claimed[wordIndex] |= mask;
    }

    /**
     * Toggle Functions
     */
    function toggleWPublic() external onlyOwner {
        isWPublic = !isWPublic;
    }

    function toggleXPublic() external onlyOwner {
        isXPublic = !isXPublic;
    }

    function toggleYPublic() external onlyOwner {
        isYPublic = !isYPublic;
    }

    function toggleZPublic() external onlyOwner {
        isZPublic = !isZPublic;
    }

    function toggleWLActive() external onlyOwner {
        isWLActive = !isWLActive;
    }

    function toggleClaimActive() external onlyOwner {
        isClaimActive = !isClaimActive;
    }

    // List of P4TCHs owned by wallet
    function patchesOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 patchCount = balanceOf(_owner);
        if (patchCount == 0) return new uint256[](0);
        else {
            uint256[] memory result = new uint256[](patchCount);
            uint256 index;
            for (index = 0; index < patchCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    // BaseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Overrides
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Withdraw
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Withdraw failed");
    }

    // Reverts
    error MaxAllowed();
    error SoldOut();
}