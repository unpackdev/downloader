// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";

/*
          _____                   _____                   _____            _____            _____                   _____                   _____                   _____          
         /\    \                 /\    \                 /\    \          /\    \          /\    \                 /\    \                 /\    \                 /\    \         
        /::\    \               /::\    \               /::\    \        /::\    \        /::\    \               /::\    \               /::\    \               /::\    \        
       /::::\    \             /::::\    \              \:::\    \       \:::\    \       \:::\    \             /::::\    \             /::::\    \              \:::\    \       
      /::::::\    \           /::::::\    \              \:::\    \       \:::\    \       \:::\    \           /::::::\    \           /::::::\    \              \:::\    \      
     /:::/\:::\    \         /:::/\:::\    \              \:::\    \       \:::\    \       \:::\    \         /:::/\:::\    \         /:::/\:::\    \              \:::\    \     
    /:::/  \:::\    \       /:::/__\:::\    \              \:::\    \       \:::\    \       \:::\    \       /:::/__\:::\    \       /:::/__\:::\    \              \:::\    \    
   /:::/    \:::\    \     /::::\   \:::\    \             /::::\    \      /::::\    \      /::::\    \     /::::\   \:::\    \     /::::\   \:::\    \              \:::\    \   
  /:::/    / \:::\    \   /::::::\   \:::\    \   ____    /::::::\    \    /::::::\    \    /::::::\    \   /::::::\   \:::\    \   /::::::\   \:::\    \              \:::\    \  
 /:::/    /   \:::\    \ /:::/\:::\   \:::\____\ /\   \  /:::/\:::\    \  /:::/\:::\    \  /:::/\:::\    \ /:::/\:::\   \:::\    \ /:::/\:::\   \:::\____\              \:::\    \ 
/:::/____/     \:::\____/:::/  \:::\   \:::|    /::\   \/:::/  \:::\____\/:::/  \:::\____\/:::/  \:::\____/:::/__\:::\   \:::\____/:::/  \:::\   \:::|    _______________\:::\____\
\:::\    \      \::/    \::/   |::::\  /:::|____\:::\  /:::/    \::/    /:::/    \::/    /:::/    \::/    \:::\   \:::\   \::/    \::/   |::::\  /:::|____\::::::::::::::::::/    /
 \:::\    \      \/____/ \/____|:::::\/:::/    / \:::\/:::/    / \/____/:::/    / \/____/:::/    / \/____/ \:::\   \:::\   \/____/ \/____|:::::\/:::/    / \::::::::::::::::/____/ 
  \:::\    \                   |:::::::::/    /   \::::::/    /       /:::/    /       /:::/    /           \:::\   \:::\    \           |:::::::::/    /   \:::\~~~~\~~~~~~       
   \:::\    \                  |::|\::::/    /     \::::/____/       /:::/    /       /:::/    /             \:::\   \:::\____\          |::|\::::/    /     \:::\    \            
    \:::\    \                 |::| \::/____/       \:::\    \       \::/    /        \::/    /               \:::\   \::/    /          |::| \::/____/       \:::\    \           
     \:::\    \                |::|  ~|              \:::\    \       \/____/          \/____/                 \:::\   \/____/           |::|  ~|              \:::\    \          
      \:::\    \               |::|   |               \:::\    \                                                \:::\    \               |::|   |               \:::\    \         
       \:::\____\              \::|   |                \:::\____\                                                \:::\____\              \::|   |                \:::\____\        
        \::/    /               \:|   |                 \::/    /                                                 \::/    /               \:|   |                 \::/    /        
         \/____/                 \|___|                  \/____/                                                   \/____/                 \|___|                  \/____/         
                                                                                                                                                                                                                                                                                                                                                                               
*/

contract CritterzWTF is ERC721AQueryable, Ownable {
    // ============ State Variables ============

    mapping(uint256 => bool) public usedHoboTownTokenIds;
    mapping(uint256 => bool) public usedHoboLootTokenIds;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    bool public paused = true;
    bool public revealed = false;

    IERC721A hoboTownWTF;
    IERC721A hoboLootWTF;

    // ============ Modifiers ============

    modifier onlyWhenNotPaused() {
        require(!paused, "the uh... contract is currently paused");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "the caller is another contract");
        _;
    }

    // ============ Constructor ============

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _hiddenMetadataUri,
        address HoboTownWTFAddress,
        address HoboLootWTFAddress
    ) ERC721A(_tokenName, _tokenSymbol) {
        setHiddenMetadataUri(_hiddenMetadataUri);
        hoboTownWTF = IERC721A(HoboTownWTFAddress);
        hoboLootWTF = IERC721A(HoboLootWTFAddress);
    }

    // ============ Core functions ============

    function mint(
        uint256[] memory unusedHoboTownTokenIds,
        uint256[] memory unusedHoboLootTokenIds
    ) external onlyWhenNotPaused callerIsUser {
        for (
            uint256 i;
            i <
            (
                unusedHoboTownTokenIds.length > unusedHoboLootTokenIds.length
                    ? unusedHoboLootTokenIds.length
                    : unusedHoboTownTokenIds.length
            );

        ) {
            require(
                hoboTownWTF.ownerOf(unusedHoboTownTokenIds[i]) ==
                    _msgSender() &&
                    !usedHoboTownTokenIds[unusedHoboTownTokenIds[i]],
                "u ain't the owner or them token ids already been used"
            );
            require(
                hoboLootWTF.ownerOf(unusedHoboLootTokenIds[i]) ==
                    _msgSender() &&
                    !usedHoboLootTokenIds[unusedHoboLootTokenIds[i]],
                "u ain't the owner or them token ids already been used"
            );
            usedHoboTownTokenIds[unusedHoboTownTokenIds[i]] = true;
            usedHoboLootTokenIds[unusedHoboLootTokenIds[i]] = true;

            unchecked {
                i++;
            }
        }

        _mint(
            _msgSender(),
            unusedHoboTownTokenIds.length > unusedHoboLootTokenIds.length
                ? unusedHoboLootTokenIds.length
                : unusedHoboTownTokenIds.length
        );
    }

    function mintMany(address[] calldata _to, uint256[] calldata _amount)
        external
        payable
        onlyOwner
    {
        for (uint256 i; i < _to.length; ) {
            _mint(_to[i], _amount[i]);

            unchecked {
                i++;
            }
        }
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "the uhh.. contract has no funds");
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function checkIfHoboTownTokenUsed(uint256 tokenId)
        public
        view
        returns (bool)
    {
        return usedHoboTownTokenIds[tokenId];
    }

    function checkIfHoboLootTokenUsed(uint256 tokenId)
        public
        view
        returns (bool)
    {
        return usedHoboLootTokenIds[tokenId];
    }

    // ============ Overrides ============

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _toString(_tokenId),
                        uriSuffix
                    )
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // ============ Setters (OnlyOwner) ============

    function setRevealed(bool _state) external onlyOwner {
        revealed = _state;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) external onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) external onlyOwner {
        paused = _state;
    }
}
