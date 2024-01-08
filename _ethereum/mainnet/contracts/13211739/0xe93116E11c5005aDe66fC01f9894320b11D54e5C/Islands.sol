// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ERC20Mintable.sol";
import "./IslandsHelper.sol";

// The islands
// Travel to diff islands and harvest shit.
// @author 1929

contract Islands is ERC721, ERC721Enumerable, Ownable {
    struct Attributes {
        uint8 resource;
        uint8 climate;
        uint8 terrain;
        uint8 taxRate;
        uint32 area;
        uint32 population;
    }

    struct Island {
        uint256 tokenId;
        ERC20Mintable resourceTokenContract;
        string resource;
        string climate;
        string terrain;
        uint32 area;
        uint32 maxPopulation;
        uint32 population;
        uint8 taxRate;
    }

    string[] public resources = ["Fish", "Wood", "Iron", "Silver", "Pearl", "Oil", "Diamond"];
    string[] public climates = ["Temperate", "Rainy", "Humid", "Arid", "Tropical", "Icy"];
    string[] public terrains = ["Flatlands", "Hilly", "Canyons", "Mountainous"];

    ERC20Mintable[] public resourcesToTokenContracts;

    uint256 constant MAX_AREA = 5_000;
    uint32 constant MAX_POPULATION_PER_SQ_MI = 2_000;

    IslandsHelper public helperContract;

    mapping(uint256 => Attributes) public tokenIdToAttributes;
    mapping(uint256 => uint256) public tokenIdToLastHarvest;

    // For future use so that expansion packs can increase/decrease the population
    // Idk what this could be used for... but probably something cool
    mapping(address => bool) public populationEditors;

    modifier onlyPopulationEditor() {
        require(
            populationEditors[msg.sender] == true,
            "You don't have permission to edit the population"
        );
        _;
    }

    constructor(
        ERC20Mintable fishToken,
        ERC20Mintable woodToken,
        ERC20Mintable ironToken,
        ERC20Mintable silverToken,
        ERC20Mintable pearlToken,
        ERC20Mintable oilToken,
        ERC20Mintable diamondToken
    ) ERC721("Islands", "ILND") {
        resourcesToTokenContracts = [
            fishToken,
            woodToken,
            ironToken,
            silverToken,
            pearlToken,
            oilToken,
            diamondToken
        ];
    }

    /** Setters */
    function addPopulationEditor(address newPopulationEditor) public onlyOwner {
        populationEditors[newPopulationEditor] = true;
    }

    function removePopulationEditor(address newPopulationEditor) public onlyOwner {
        populationEditors[newPopulationEditor] = false;
    }

    function setHelperContract(IslandsHelper helperContract_) public onlyOwner {
        helperContract = helperContract_;
    }

    function setPopulation(uint256 tokenId, uint32 population) public onlyPopulationEditor {
        require(population <= getIslandInfo(tokenId).maxPopulation, "Population is over max");
        tokenIdToAttributes[tokenId].population = population;
    }

    /** Getters */
    function getTaxIncome(uint256 tokenId) public view returns (ERC20Mintable, uint256) {
        return helperContract.getTaxIncome(tokenId);
    }

    function getRandomNumber(bytes memory seed, uint256 maxValue) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(seed))) % maxValue;
    }

    function getTokenIdToAttributes(uint256 tokenId) public view returns (Attributes memory) {
        return tokenIdToAttributes[tokenId];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return helperContract.tokenURI(tokenId);
    }

    function getPopulationPerSqMi(uint256 tokenId) public pure returns (uint32) {
        return uint32(getRandomNumber(abi.encode(tokenId), MAX_POPULATION_PER_SQ_MI)) + 10;
    }

    function getIslandInfo(uint256 tokenId) public view returns (Island memory) {
        require(_exists(tokenId), "Island with that tokenId doesn't exist");

        Attributes memory attr = tokenIdToAttributes[tokenId];

        uint32 populationPerSqMi = getPopulationPerSqMi(tokenId);
        uint32 maxPopulation = populationPerSqMi * attr.area;

        return
            Island({
                tokenId: tokenId,
                resource: resources[attr.resource],
                resourceTokenContract: resourcesToTokenContracts[attr.resource],
                climate: climates[attr.climate],
                terrain: terrains[attr.terrain],
                area: attr.area,
                maxPopulation: maxPopulation,
                population: attr.population,
                taxRate: attr.taxRate
            });
    }

    /** State modifications */
    function mint(uint256 tokenId) public {
        require(!_exists(tokenId), "Island with that id already exists");
        require(
            (tokenId <= 9900) || (tokenId <= 10_000 && tokenId > 9900 && msg.sender == owner()),
            "Island id is invalid"
        );

        Attributes memory attr;

        uint256 value = getRandomNumber(abi.encode(tokenId, "r"), 1000);
        attr.resource = uint8(value < 700 ? value % 3 : value % 7);

        value = getRandomNumber(abi.encode(tokenId, "c"), 1000);
        attr.climate = uint8(value % 6);

        value = getRandomNumber(abi.encode(tokenId, "t"), 1000);
        attr.terrain = uint8(value % 4);

        value = getRandomNumber(abi.encode(tokenId, "ta"), 1000);
        attr.taxRate = uint8(value % 50) + 1;

        attr.area = uint32(getRandomNumber(abi.encode(tokenId, "a"), MAX_AREA)) + 1;

        uint32 populationPerSqMi = getPopulationPerSqMi(tokenId);
        uint32 maxPopulation = populationPerSqMi * attr.area;
        attr.population =
            (uint32(maxPopulation * getRandomNumber(abi.encode(tokenId), 100)) / 100) +
            10;

        tokenIdToAttributes[tokenId] = attr;
        tokenIdToLastHarvest[tokenId] = block.number;

        _safeMint(msg.sender, tokenId);
    }

    function harvest(uint256 tokenId) public {
        (ERC20Mintable resourceTokenContract, uint256 taxIncome) = helperContract.getTaxIncome(
            tokenId
        );

        tokenIdToLastHarvest[tokenId] = block.number;
        resourceTokenContract.mint(ownerOf(tokenId), taxIncome);
    }

    /** Library overrides */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
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
