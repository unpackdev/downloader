// SPDX-License-Identifier: MIT

/*
    
The last window is a series around the sentiment of feeling lost with just one window out.
It was created using data from the 256ART genesis series. 

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@&    -** --   &    &&%#/*,. @- ** -***             **-* --- *-*     %# ///(/&@
@@&                               @&&%          #/    *#(((            ##(/   &@
@@&                                   *                %(/..,,         #***** &@
@@&                                  (/                  /,(           (////* &@
@@&  %%%                             #/                                (//    &@
@@&@@@%%%                &&@                                 ###****          &@
@@&                          ....%((                            %/            &@
@@&               ...           &%((          *             ...               &@
@@&               ...@@@@@@@@@@@@@@@@@@@@@@@@@***, @@@@@@@@@...               &@
@@&               ...@@@@@@@@@@@@@@@@@@@@@@@@@@@*.@@@@@@@@@@...     (((#/  &%%&@
@@&               ...@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@...     &####  %%%&@
@@&               ...@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@...     &###   ,,,&@
@@&/(             ...@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@((*          ///,,&@
@@&***            ...@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@**,@@@@%(..          ///&*&@
@@&,//(*          ...@@@@@@@&((*@@@@@@@@@@@@@@@@@@@@@%@@@@@@...  (((#@@@@  (/(&@
@@&///            ...@@@@@@@@@@@@@@@@@@@/*@@@@@@@@@@@@@@@@@@...  ((((@@%@    /&@
@@&//      @@##%% ...@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@...  ((( #@(@    *&@
@@&     #( %@@ #% ...@@@@@@@@@@@@@@@@@@@@@@@@@##/@@@@@@@@(@@...              /&@
@@&     #%%%     &(((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@...               &@
@@&     %%%%     &&#,@@@@@@@@@/,***@@@@@@@@@@@@@@@@@@@@@@@@@...               &@
@@&   #////%     %&*#@@@@@@/(****@@@@@@@@@@@@@@@@@@@@@@@@@@@...               &@
@@&   %##(/       ...@@@@&%###//@@@@@@@@@@@@@@@@@@@@@@@@@@@@...               &@
@@&   #%%/(       ...@@@@##@#///@@@@@(,,,*@@@@@@@@@%@@@@@@@@...  &((##   .,   &@
@@&   ###(/    @@&..                 /(/**       #***       ...  &&##.   ,,,,,&@
@@&  #%        @(& %%               %% (            / ###    ####&(#*%   ,,.,,&@
@@&  ##        @@@                @@%%&&     ///,     &&.%%@@/@%%%%        ,./&@
@@&  %#                             @&       \\\,           %&@%%%           (&@
@@&                                 %#//                       (,             &@
@@&  /////               ##%%/)    ..%,(      /#@@@@%###/,                    &@
@@&  -----               *-*-*-      **---    ***** -****          * - ****   &@
@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


*/
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract THELASTWINDOW is ERC721, IERC2981, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public maxSupply = 1024;
    uint256 public maxMintAmount = 16;
    uint256 public price = 25600000000000000;
    bool public saleIsActive = false;
    address public the256ArtAddress;
    mapping(uint256 => bool) public freeMints;
    string public base64script;
    string public base64packages;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _base64script,
        string memory _base64packages,
        uint256[] memory _freeMints,
        address _genesisContract
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setThe256ArtSmartContractAddress(_genesisContract);
        setScript(_base64script);
        setPackages(_base64packages);
        addFreeMints(_freeMints);
    }

    function require256ArtOwner(uint256 a256ArtId) private view {
        ERC721 theAddress = ERC721(the256ArtAddress);

        require(
            theAddress.ownerOf(a256ArtId) == _msgSender(),
            "256ART not owned"
        );
    }

    Counters.Counter private _counter;

    function getMintCount() public view returns (uint256) {
        return _counter.current();
    }

    function mint(uint256[] calldata the256ArtIds) public payable {
        uint256 count = the256ArtIds.length;

        require(saleIsActive, "Sale not active");
        require(count > 0, "Must mint at least one");
        require(count <= maxMintAmount, "Multimint max is 16");
        require(
            _counter.current() + count - 1 < maxSupply,
            "Exceeds max supply"
        );

        uint256 finalPrice = 0;

        for (uint256 i = 0; i < count; i++) {
            require256ArtOwner(the256ArtIds[i]);

            if (!isFreeMint(the256ArtIds[i])) {
                finalPrice += price;
            }
        }

        require(msg.value >= finalPrice, "Insufficient payment");

        for (uint256 i = 0; i < count; i++) {
            _safeMint(_msgSender(), the256ArtIds[i]);
            _counter.increment();
        }
    }

    function remainingSupply() public view returns (uint256) {
        return maxSupply - _counter.current();
    }

    function tokenSupply() public view returns (uint256) {
        return _counter.current();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function addFreeMints(uint256[] memory _ids) public onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            freeMints[_ids[i]] = true;
        }
    }

    function removeFreeMints(uint256[] memory _ids) public onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            delete freeMints[_ids[i]];
        }
    }

    function isFreeMint(uint256 _id) public view returns (bool) {
        return freeMints[_id];
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function setThe256ArtSmartContractAddress(address _address)
        public
        onlyOwner
    {
        the256ArtAddress = _address;
    }

    function setSaleIsActive(bool isActive) public onlyOwner {
        saleIsActive = isActive;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setScript(string memory _base64script) public onlyOwner {
        base64script = _base64script;
    }

    function setPackages(string memory _base64packages) public onlyOwner {
        base64packages = _base64packages;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function royaltyInfo(uint256, uint256 salePrice)
        external
        pure
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (
            address(0x4d95B1ea2a8a021fE98b5D60E5f835Aa7bA3362B),
            (salePrice * 512) / 10000
        );
    }
}
