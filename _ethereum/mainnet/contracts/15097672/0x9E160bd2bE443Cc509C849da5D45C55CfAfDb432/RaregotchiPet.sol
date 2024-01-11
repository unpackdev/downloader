// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ECDSA.sol";
import "./Strings.sol";

contract RaregotchiPet is ERC721 {
    event NewPet(uint256 tokenId, uint256 toyId, uint256[] parentIds);

    bool private isFrozen = false;
    string private baseUri = "";
    address private toyContractAddress;
    address private breedingContractAddress;

    uint256 public totalSupply = 0;
    mapping(uint256 => uint16) public tokenToyId;
    mapping(uint256 => uint256[]) public tokenParents;

    uint16 maxPetId = 9999;
    uint16 maxToyId = 3000;

    constructor() ERC721("RaregotchiPet", "RGP") {}

    modifier contractIsNotFrozen() {
        require(isFrozen == false, "This function can not be called anymore");
        _;
    }

    modifier callerIsToyContract() {
        require(
            msg.sender == toyContractAddress,
            "The caller must be Raregotchi Toy Contract"
        );
        _;
    }

    modifier callerIsBreedingContract() {
        require(
            msg.sender == breedingContractAddress,
            "The caller must be Raregotchi Breeding Contract"
        );
        _;
    }

    /**
     * @dev Set the open baseUri
     */
    function setBaseUri(string calldata _baseUri)
        external
        onlyOwner
        contractIsNotFrozen
    {
        baseUri = _baseUri;
    }

    /**
     * @dev Set the toy contract address
     */
    function setToyContractAddress(address _toyContractAddress)
        external
        onlyOwner
        contractIsNotFrozen
    {
        toyContractAddress = _toyContractAddress;
    }

    /**
     * @dev Set the toy contract address
     */
    function setBreedingContractAddress(address _breedingContractAddress)
        external
        onlyOwner
        contractIsNotFrozen
    {
        breedingContractAddress = _breedingContractAddress;
    }

    /**
     * @dev Sets the isFrozen variable to true
     */
    function freezeSmartContract() external onlyOwner {
        isFrozen = true;
    }

    function mint(
        address destinationAddress,
        uint16 toyId,
        uint256[] calldata tokenIds
    ) external callerIsToyContract {
        require(toyId > 0 && toyId <= maxToyId, "Invalid toy id");
        totalSupply += tokenIds.length;

        _batchMint(destinationAddress, tokenIds);

        for (uint16 i; i < tokenIds.length; i++) {
            require(
                tokenIds[i] > 0 && tokenIds[i] <= maxPetId,
                "Invalid pet id"
            );
            tokenToyId[tokenIds[i]] = toyId;
            emit NewPet(tokenIds[i], toyId, new uint256[](0));
        }
    }

    function breedingMint(
        address destinationAddress,
        uint256 tokenId,
        uint256[] calldata parents
    ) external callerIsBreedingContract {
        totalSupply++;
        tokenParents[tokenId] = parents;

        _mint(destinationAddress, tokenId);

        emit NewPet(tokenId, 0, parents);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseUri, Strings.toString(_tokenId)));
    }
}

//                                                                                                       #@@@@#
//                                                                                                   @@@@@@@@@@@@@@@@@@@@@@@@@@
//                                                                                                 @@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@
//                                                                                  @@@@@@@@@@@@@@@@@@@@@@                     /@@@@@.     @@@@@@@&.@@@@@@
//                                                                          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.                                  @@@@      @@@
//                                                                    /@@@@@@@@@@@@@@/                     @                                            .@@@
//                                                                @@@@@@@@@@@@                              @*                                           @@@@
//                                                            @@@@@@@@@@,                                      ,@@@@@@@,                                  @@@@@
//                                                        @@@@@@@@@@                                                     @&                                 @@@@@@
//                                                     @@@@@@@@@                                                          @                                    @@@@@
//                                                  @@@@@@@@@                                                             @%                                     @@@@
//                                                @@@@@@@@                                                                 @   @@#@                               @@@
//                                              @@@@@@@                                                                             &@@                           @@@
//                                            @@@@@@@                                                                                  /#                         @@@@
//                                          @@@@@@#                                                                                     @&                         @@@@
//                                        @@@@@@&                                                                                          #@@                      @@@@@
//                                      @@@@@@@                            ,@@@@@@@@                                   @@@@@@@@                @                      @@@@@
//                                     @@@@@@                             @@@@@@@@@@@#                               @@@@@@@@@@@@               @                       @@@@@
//                                    @@@@@@                            /@@@@@@@@@@@@@@@@@@@@                       @@@@@@@@@@@@@@@@@@@@        @                         @@@&
//                                  @@@@@@                             .@@@@@@@@@@@@@@@@@@@@@@@&                   @@@@@@@@@@@@@@@@@@@@@@@@     @      @@@@@               @@@
//                                 @@@@@@                              @@@@@@@@@@@@@@@@@@@@@@,                    @@@@@@@@@@@@@@@@@@@@@@@       @    @@     @@,            @@@
//                                @@@@@@                              @@@@@@@@@@@@@@@@@@@                        @@@@@@@@@@@@@@@@@@@            @/   @             /@@     @@@
//                               &@@@@@                               @@@@@@@@@@@@@@@@@@@                        @@@@@@@@@@@@@@@@@@@.            *@@%                 @@@@@@@&
//                               @@@@@                                @@@@@@@@@@@@@@@@@@@@                       @@@@@@@@@@@@@@@@@@@@                                  @@@@@@
//                              @@@@@                                (@@@@@@@@@@@@@@@@@@@@                       @@@@@@@@@@@@@@@@@@@@                                   @@@@@
//                             @@@@@@         @@@@@@@@@@@            @@@@@@@@@@@@@@@@@@@@@                      &@@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@            @@@@@&
//                             @@@@@       #@, @@@@@@@@@@@@&         ,@@@@@@@@@@@@@@@@@@@@                      *@@@@@@@@@@@@@@@@@@@@         #@@@@@@@@@@@@ /@*          @@@@@
//                            %@@@@@      @@@@  @@@@@@@@@@ @@         @@@@@@@@@@@@@@@@@@@@                       @@@@@@@@@@@@@@@@@@@@        @@ @@@@@@@@@@  @@@@         @@@@@,
//                            @@@@@      @%@@.              @(        @@@@@@@@@@@@@@@@@@@.                       @@@@@@@@@@@@@@@@@@@(       (@              .@@&,        .@@@@@
//                            @@@@@      @                            @@@@@@@@@@@@@@@@@@@                        @@@@@@@@@@@@@@@@@@@        /                             @@@@@
//                            @@@@@        @@@@@@@@@@*                 @@@@@@@@@@@@@@@@@@                         @@@@@@@@@@@@@@@@@@                /@@@@@@@@@@           @@@@@
//                            @@@@@                @                  @@@@@@@@@@@@@@@@@@                         *@@@@@@@@@@@@@@@@@                   @                   @@@@@
//                            @@@@@                @@              @@@@@@@@@@@@@@@@@@@@                       @@@@@@@@@@@@@@@@@@@@                   @#                   @@@@@
//                            @@@@@                  &               @@@@@@@@@@@@@@@@@                          %@@@@@@@@@@@@@@@@                   @@                    @@@@@
//                            @@@@@               @@@@@                    @@@@@@@@@                                  @@@@@@@@@,                   @@@@@                  @@@@@
//                            @@@@@             ,@@  @@@                      &@@                                        @@@                      @@@  #@@               @@@@@@
//                             @@@@@           @@.    @@@                                                                                        @@@     @@              @@@@@
//                             @@@@@           @(      @@@@                                                                                    @@@%       @/            *@@@@@
//                              @@@@@         @@         @@@@                                                                                @@@@         @@            @@@@@
//                              @@@@@         ,@*         @@@@@                                                                            @@@@&         @@            @@@@@@
//                               @@@@@         &@@          @@@@@                                                                        @@@@@          @@            @@@@@@
//                                @@@@@          &@@@         @@@@@@                                                                  @@@@@@          @@@            ,@@@@@
//                                 @@@@@              @@@@@@@@@@@@@@@@@                                                            @@@@@@@@@@@@@@@@@@.              ,@@@@@
//                                  @@@@@                      @@  *@@@@@@,                                                    *@@@@@@   @@                        &@@@@@
//                                   @@@@@                    @@@      @@@@@@@@                                            @@@@@@@@       @@                      @@@@@@
//                                    @@@@@@                  (@@          @@@@@@@@@@                                @@@@@@@@@@           @@                     @@@@@.
//                                      @@@@@                  @@               @@@@@@@@@@@@@@@@@@&&#///#&@@@@@@@@@@@@@@@@               *@                    @@@@@@
//                                       @@@@@@                 @@                     #@@@@@@@@@@@@@@@@@@@@@@@@@@(                      @@                  *@@@@@%
//                                         @@@@@.                @@                                @@@@                                 @@                  @@@@@@
//                                           @@@@@.               @@@                            @@/  @@@                             @@/                 @@@@@@
//                                             @@@@@@               @@@                        @@@      @@@                         @@#                 @@@@@@
//                                               @@@@@@                @@@&                @@@@            @@@%                 @@@@                 @@@@@@@
//                                                 .@@@@@@                  @@@@@@@@@@@@@@                     /@@@@@@@@@@@@@@@.                  @@@@@@@
//                                                    @@@@@@@                                                                                  @@@@@@@%
//                                                       @@@@@@@                                                                            @@@@@@@@
//                                                          *@@@@@@@                                                                    @@@@@@@@
//                                                              @@@@@@@@@                                                          @@@@@@@@@*
//                                                                   @@@@@@@@@%                                              (@@@@@@@@@@
//                                                                        @@@@@@@@@@@@@                             ,@@@@@@@@@@@@@&
//                                                                               @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//                                                                                          %@@@@@@@@@@@@@@@@@@@%
