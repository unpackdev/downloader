// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./IFactoryERC721.sol";
import "./IdeasOfMountains.sol";

/**
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#&%*,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,.,.,,,,,..,,,,,,.,,,%&&&&%*,,,,,,,,,...,.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,.,,,,,...............,...,,%&&&&&&&%,,,,,,%&(,,,,,,,,,,,,,,,,,,,,,,.,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,..,,,,,,...............,,,(%&&&&&&&&&%%%%&&&&&%,*%&%#,,,,..,.,,,,,,,,,.,,,,,,,,,,,,,,,,,,,,,
,,,.....,,,,,,,.................,*%&&&&&&&&&&&&&&&&&&&&&&&&&&%,,,.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
.....,,,,.,....................,#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%*,**,,,,,,,*%&&&&(,,,,,,,,,,,,,,,,,,,
......,,....................,%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%*,,%#*%&&&&&&%%%%%*,,,,,,,,,,,,,
..............,,,,,,,,,,,,,*%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%/&&&&&&&&&&&&&&&&%/,,,,,,,,,,,
.,,.,,,,,,,,,,,,,,,,,,,,,*%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%%,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,*,,,#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%,,,,,,,,
,,,,,,,,,,,,,,,,**%%&&&%%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&/,,,,,,
,,,...........,#%%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%,,,,
............,%%%%%%%%%%%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%*,
........,,,#%%%%%%%%%%%%%%%%%%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%
.,.,,,,,,#%%%%%%%%%%%%%%%%&%%%%%%%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
...,*##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
,/##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&%%&&&&&&&&&%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
###%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&%%%%%%&&&%&%&&&&%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
####%%#%%%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&%%&&&&&&%&&&&&%&%&%&&&&&&&&&&&&&&&&&&&&&&&&&&&&
####%#######%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&%%%%%%%%%%%%&%&&%&&&&&&%&%&&&%&&&&&&%&&&%&
##############%%%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&%&&&&&%%%%%%%%%&%%%&%%%%%&
###################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&%%%%%%%%%%&%%%%%&%&&
#####################%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&%%&&&&
######################%%#%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&&&&&&&&
###########################%#%%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&&&&&&&&&&&&&&
##################################%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&%&&&&&&&&&&&&&&&&&&&&&
###############################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
               
               'This artwork is my reaction to the ephemeral nature of digital data.'
                Mountain 93


       IDEAS OF MOUNTAINS

       2021

       Sterling Crispin
       
       https://www.sterlingcrispin.com/ideas_of_mountains.html
 */
contract IdeasOfMountainsFactory is FactoryERC721, Ownable {
    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    address public proxyRegistryAddress;
    address public nftAddress;
    // TODO: what is this base URI
    string public baseURI = "ipfs://QmT2FTeSJvvfg8vC5A62Wy6xmX64vmLebgJmp7hXdTZJ38/";

    /*
     * Enforce the existence of only 210 Mountains
     */
    uint256 MOUNTAIN_SUPPLY = 210;

    constructor(address _proxyRegistryAddress, address _nftAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;
    }

    // Open Zeppelin function returning token collection name
    function name() override external pure returns (string memory) {
        return "Ideas Of Mountains";
    }
    // Open Zeppelin function returning symbol name
    function symbol() override external pure returns (string memory) {
        return "MOUNTAINS";
    }
    // Open Zeppelin function returning support of factory
    function supportsFactoryInterface() override public pure returns (bool) {
        return true;
    }
    // Open Zeppelin Ownership
    function transferOwnership(address newOwner) override public onlyOwner {
        super.transferOwnership(newOwner);
    }

    function mint(address _toAddress) override public {

        assert( owner() == _msgSender() );

        IdeasOfMountains mountains = IdeasOfMountains(nftAddress);
        uint256 mountainSupply = mountains.totalSupply();
        if(mountainSupply < MOUNTAIN_SUPPLY){
            mountains.mintTo(_toAddress);
        }
    }

    // Returns metadata on IPFS
    function tokenURI(uint256 _optionId) override external view returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_optionId)));
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        if (owner() == _owner && _owner == _operator) {
            return true;
        }

        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (
            owner() == _owner &&
            address(proxyRegistry.proxies(_owner)) == _operator
        ) {
            return true;
        }

        return false;
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return owner();
    }
}
