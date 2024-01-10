// SPDX-License-Identifier: MIT

/*

 █████╗ ██████╗ ███╗   ███╗ ██████╗    ██╗  ██╗██╗███████╗████████╗██╗   ██╗███╗   ██╗███████╗
██╔══██╗██╔══██╗████╗ ████║██╔════╝    ██║ ██╔╝██║██╔════╝╚══██╔══╝██║   ██║████╗  ██║██╔════╝
███████║██████╔╝██╔████╔██║██║         █████╔╝ ██║███████╗   ██║   ██║   ██║██╔██╗ ██║█████╗
██╔══██║██╔══██╗██║╚██╔╝██║██║         ██╔═██╗ ██║╚════██║   ██║   ██║   ██║██║╚██╗██║██╔══╝
██║  ██║██║  ██║██║ ╚═╝ ██║╚██████╗    ██║  ██╗██║███████║   ██║   ╚██████╔╝██║ ╚████║███████╗
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝    ╚═╝  ╚═╝╚═╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═══╝╚══════╝


MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM9MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMB>(~MMMMMMMMMMMMMM3<MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM8:;::~dMMMMMMMMMMM@:::(MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM8:::::~~JMMMMMMMMMM5:::::JMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMB<~:~(Jsc~(MMMMMMMMMt~~((::_dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM5_~~(zuuZ$~(MMMMMMMMF_.(uuo_~(MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM>.~.(zuuZZt_`MMMMMMM#_.(zuuun~~JMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM#~..(zvvzVV7! `(T"""""^  .OwzuuI~_JMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMM@~~..<<!__.````````````````` ~?zvI._JMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMM#:~_ ` ...`...````````````````````   _MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMM>~.........`...`````````````````````  dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMF:~~~..x........````````````````````.`.(MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMmHHkA&J-.XHJ-.......``````` ,.,```````....MMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMH@HHfyyo(HWZX&.~...J{````.X%`jn,````1,..(uX#yyWHNMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMM#;dggHWyZkHHWXZZX&(WXn.``,OOO.JOO%```,u.(XuXBZyWMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMD;<WH@HHkkZuzXXZZZkbWWn...1?? .<~` ` wV(uuX0zXXNMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMM>::;::<7WHkkuzdpWWXdbp$..`````    ``.XtXXXWvvwMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMM#;;:;:::~:dgHkkzzWVSdfyXzw+.````````.wvzXXXzvwdMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMM#;:::::~~(+YTWHkkXXWkXkXZUkw{``````.XvXXZZXXUNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMM@;::?h-~(#<~~~~~jWkuXWbkXWXkI``````(yXXX0z2(:MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMb;;::X$JHb<::::(HX4HkuXWWWXu}``````(XyXUuuZ_+MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMb>>;+WrzWNx<;;;?MmH@(TWkkkk!```` ``` jkV=?3(IMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMM@>;;XJp/7WMHmaaggga&&++dMM#l````````` TMY"7=(MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMM@>>>dhXWhJJJ.~~_~.~~..~_?TZZl.````````.I...JSMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMM#?>>>7Hx7YYYT5-ze---_.~~~~~?4{..``````` ~.wX>MHWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMNz???>>?Ukk+:~_((THWWX+~~~~~......```````.wuuWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMb???>>;;?HWHHWfVW&XVXzl~~~~~~~.....``````.OzzXMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMM#==1ggmmagMMYYTWkkWkkzv<(XWX<~~~...```````.OwXMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMs=dNHMM#MMN+:;;?HH97WXwXWWXl~~~~...`````` ,XdMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMNzvMNHMMMMMMN,<dh/<;>?Wkkk$;;<___(Np-....JtNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMM#lzHNHMMMMMMMMMMMNJ>???=?>>??1z1+<(<:::~:(MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMKlllzXMMkpMMMMMMMMNJ1llz??=ltrwOz1++<>>;dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMROOl==OTMHWWMMMMMMMMNgQAOz=OwXuXrOu&&jMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNmwOllllZHNWMMMMMMMMMMMKz;WkkqkqpW6iMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNmwOtll=vHHWMMMMHMMMMMkukqkkW>(jNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkwOOl?vTHM#>_dHpppbbkkkKl<_MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNmkwOz?JMI+:dpppbbkkkWHv>jMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM@@@@NmkwzdHy+JpbbbkkkbqkfWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMM@@@H@@H@H@H@H@@MHkwMNQkkQQHHHYYYWMM@@@@HMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMM@M@H@HH@HH@@H@H@H@HH@H@@HmUMMBI++&&&ugH@@@@@@@@@@HMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMM@@HH@@H@H@@HH@H@HH@HH@HHHH@HH@MHHHHM@H@@H@H@H@@@@@@@@@MMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMH@HHHHHH@H@HH@HH@H@HH@HHH@HHHHHHHHHHHHH@HH@@H@@H@H@@@@@@@MMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMH@H@@HHH@HH@H@HHHHHHHHHHHHHHHHHHHHHHHHH@HH@@H@@@@H@@H@@gMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMM@HH@@HHH@HHH@HH@HHHHHHHHHHHHHHHHHHHHHH@@H@@H@@H@@H@@MMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMM@HH@HH@HH@H@HH@HHHHHHHHHH#H#HHHHHHH@H@@H@@H@@@MHNMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMNMM@@H@HHHHH@HHH@HHHHHHHHH#HHHHHHHHHH@@@@MHNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNMMH@MHMMHHHHHHHHHHHHHMMHHM@MNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

*/

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC2981ContractWideRoyalties.sol";

contract ARMC_kitsune is ERC721, Ownable, ERC2981ContractWideRoyalties {
    using Strings for uint256;

    string public uriPrefix = "";
    string public uriSuffix = ".json";

    uint256 public maxSupply = 1111;
    uint256 public cost = 0.05 ether;
    uint256 private miniMintableTokenId = 0;
    uint256[] private mintedTokenIdList;

    bool public paused = true;
    bool public isFrozen = false;

    event NewNFTMinted(
        address sender,
        uint256 tokenId,
        uint256[] mintedTokenIdList
    );

    constructor() ERC721("ARMC kitsune", "ARMCK") {}

    modifier mintCompliance(uint256 _tokenId) {
        require(
            _tokenId < maxSupply,
            "The tokenId must lower than max supply."
        );
        require(
            mintedTokenIdList.length < maxSupply,
            "All NFTs were already minted."
        );
        _;
    }

    modifier whenNotFrozen() {
        require(isFrozen == false, "The contract is already frozen.");
        _;
    }

    function freezeMetadata() external onlyOwner {
        require(isFrozen == false, "Metadata ia already frozen!");
        isFrozen = true;
    }

    function totalSupply() public view returns (uint256) {
        return mintedTokenIdList.length;
    }

    function mintedSalesTokenIdList() external view returns (uint256[] memory) {
        return mintedTokenIdList;
    }

    function getMintableTokenId(uint256 _tokenId)
        private
        view
        returns (uint256)
    {
        if (_exists(_tokenId)) {
            for (
                uint256 tokenId = miniMintableTokenId;
                tokenId < maxSupply;
                tokenId++
            ) {
                if (!_exists(tokenId)) return (tokenId);
            }
        }
        return (_tokenId);
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mint(uint256 _tokenId) public payable mintCompliance(_tokenId) {
        require(paused == false, "The contract is paused!");
        require(
            msg.value >= cost,
            string(
                abi.encodePacked(
                    "The value must be like: VALUE >= ",
                    cost.toString()
                )
            )
        );
        uint256 mintableTokenId = getMintableTokenId(_tokenId);
        mintedTokenIdList.push(mintableTokenId);
        _safeMint(msg.sender, mintableTokenId);
        if (miniMintableTokenId == mintableTokenId)
            miniMintableTokenId = getMintableTokenId(mintableTokenId + 1);
        emit NewNFTMinted(msg.sender, mintableTokenId, mintedTokenIdList);
    }

    function mintForAddress(address _receiver, uint256 _tokenId)
        public
        mintCompliance(_tokenId)
        onlyOwner
    {
        mintedTokenIdList.push(_tokenId);
        _safeMint(_receiver, _tokenId);

        if (miniMintableTokenId == _tokenId)
            miniMintableTokenId = getMintableTokenId(_tokenId + 1);
        emit NewNFTMinted(_receiver, _tokenId, mintedTokenIdList);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 0;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

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

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setUriPrefix(string memory _uriPrefix)
        public
        onlyOwner
        whenNotFrozen
    {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix)
        public
        onlyOwner
        whenNotFrozen
    {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setRoyaltyInfo(address _royaltyAddress, uint256 _percentage)
        public
        onlyOwner
    {
        _setRoyalties(_royaltyAddress, _percentage);
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os, "withdraw is failed!!");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}
