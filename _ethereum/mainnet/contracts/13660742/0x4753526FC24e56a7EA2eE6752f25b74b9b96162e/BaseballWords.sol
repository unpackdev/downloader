// contracts/BaseballWords.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721Enumerable.sol";

import "./Ownable.sol";
// import "./console.sol";
import "./base64.sol";
import "./structs.sol";

import "./Words.sol";
import "./Baseballs.sol";
import "./TokenUri.sol";

contract BaseballWords is ERC721Enumerable, Ownable {

    struct Mappings {

        //Map project id to token index nonce
        mapping(uint256 => uint256) projectTokenIndexNonce;

        //Map project id to project
        mapping(uint256 => Project) projects;

        //Map project id and attribute category id to AttributeProbability[]
        mapping(uint256 => mapping(uint256 => AttributeProbability[])) attributeProbabilities;

    }

    struct Contracts {
        Words words;
        Baseballs baseballs;
        TokenUri tokenUri;
    }

    Contracts private _contracts;
    Mappings private _mappings;


    uint256 public attributeNonce = 0;

    // Use a split bit implementation.
    // Store the type in the upper 128 bits..
    uint256 constant TYPE_MASK = uint256(type(uint128).max) << 128;

    // ..and the non-fungible index in the lower 128
    uint256 constant NF_INDEX_MASK = type(uint128).max;


    constructor(address wordsAddress, address baseballsAddress, address tokenUriAddress) ERC721("Baseball Words", "BWORDS") {
        _contracts.words = Words(wordsAddress);
        _contracts.baseballs = Baseballs(baseballsAddress);
        _contracts.tokenUri = TokenUri(tokenUriAddress);

    }


    // Map attributeCategory id + tokenId to attribute id
    mapping(uint256 => mapping(uint256 => uint256)) private _tokenAttributes;


    function tokenAttribute(uint256 attributeCategoryId, uint256 tokenId) public view returns (uint256) {
        return _tokenAttributes[attributeCategoryId][tokenId];
    }

    function tokenIdToProjectId(uint256 _tokenId) public pure returns (uint256 _projectId) {
        return _tokenId & TYPE_MASK;
    }

    function tokenIdToIndex(uint256 _tokenId) public pure returns(uint256) {
        return _tokenId & NF_INDEX_MASK;
    }

    function tokenByProjectAndIndex(uint256 projectId, uint256 index) public pure returns (uint256) {
        return projectId | index;
    }

    function mint(uint256 projectId) external {

        /**
        Checks
         */

        //Validate the project exists.
        validProject(projectId);

        //Validate it's mintable. 
        require(_mappings.projects[projectId].mintable == true, "Non-mintable project");

        //Validate there are still quantities available. 
        require(_mappings.projects[projectId].minted < _mappings.projects[projectId].maxSupply, "Max supply minted");

        //Get cost
        uint256 burnFee = _mappings.projects[projectId].burnFee;
        require(burnFee > 0, "No burn fee."); //Sanity check. Already can't add a project with a zero burn fee.

        //Validate we have enough baseballs. 
        require(_contracts.baseballs.balanceOf(_msgSender()) >= burnFee, "Not enough balls"); 
 

        //Get balance

        /**
            Effects
         */

        //Increase max project index
        uint256 index = ++_mappings.projectTokenIndexNonce[projectId];
        uint256 tokenId  = projectId | index;


        //Loop through all the attribute categories and pick an attribute for this NFT
        uint256[] memory attributeCategoryIds = _mappings.projects[projectId].attributeCategoryIds;

        for (uint256 i=0; i < attributeCategoryIds.length; i++) {
            _tokenAttributes[attributeCategoryIds[i]][tokenId] = _getAttribute(projectId, attributeCategoryIds[i]);
            attributeNonce++;
        }


        //Increase minted
        _mappings.projects[projectId].minted++;

        //Burn Baseballs
        _contracts.baseballs.burnFrom(_msgSender(), burnFee); 


        /**
            Interactions
         */

        //Mint
        _safeMint(_msgSender(), tokenId, "");

    }

    function _getAttribute(uint256 projectId, uint256 categoryId) private view returns (uint256 _attributeId) {

        uint256 random = attributeRoll(projectId, attributeNonce); 

        AttributeProbability[] memory ap = getAttributeProbabilities( projectId, categoryId);

        uint256 total = 0;

        for (uint256 i=0; i < ap.length; i++) {

            AttributeProbability memory prob = ap[i];
            total += prob.probability;
            if (random <= total) return prob.attributeId;
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return _contracts.tokenUri.tokenURI(tokenId, this.tokenIdToProjectId(tokenId), this.tokenIdToIndex(tokenId), address(this));
    }


    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }






















    function createProject(
        string[] calldata text, // [0] name, [1] description, [2] ipfs
        uint256[] calldata mintInfo, // [0] maxSupply, [1] burnFee
        uint256[] calldata attributeCategoryIds,
        uint256[][] calldata attributeProbabilities
    ) external onlyOwner returns (uint256) {

        require(bytes(text[0]).length > 0, "Name is empty");
        require(bytes(text[1]).length > 0, "Description is empty");
        require(mintInfo[0] > 0, "Max supply is zero");
        require(bytes(text[2]).length > 0, "IPFS is empty");
        require(mintInfo[1] > 0, "Invalid burnFee");
        require(attributeCategoryIds.length > 0, "No attribute categories");
        require(attributeProbabilities.length == attributeCategoryIds.length, "Input size mismatch");

        uint256 totalBurnFee = mintInfo[0] * mintInfo[1];
        require(totalBurnFee + _burnFeeSum < 249173 ether, "Burn fee too high");

        //Update burn fee
        _burnFeeSum = totalBurnFee + _burnFeeSum;

        // Store the type in the upper 128 bits
        uint256 _id = (++_projectNonce << 128);

        //Create project attributes
        _createProjectAttributes(_id, attributeCategoryIds, attributeProbabilities);

        //Map struct
        _mappings.projects[_id].id = _id;
        _mappings.projects[_id].name = text[0];
        _mappings.projects[_id].description = text[1];
        _mappings.projects[_id].maxSupply = mintInfo[0];
        _mappings.projects[_id].burnFee = mintInfo[1];
        _mappings.projects[_id].ipfs = text[2];
        _mappings.projects[_id].mintable = false;
        _mappings.projects[_id].attributeCategoryIds = attributeCategoryIds;

        projectIds.push(_id);

        return _id;

    }

    function activateProject(uint projectId) external onlyOwner {
        validProject(projectId);
        _mappings.projects[projectId].mintable = true;
    }

    function attributeRoll(uint256 projectId, uint256 counter) public pure returns (uint256) {
        
        //not actually random and mostly predictable but it's fine

        uint256 max = 1000000;
        uint256 seed = uint256(keccak256(abi.encodePacked(projectId, counter)));
        return (seed - ((seed / max) * max));

    }


    function svg(uint256 tokenIndex, uint256 maxSupply) public view returns (string memory) {

        return string(
            abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 350 350' style='background:#56ab2f'><g><text font-size='5em' x='50%' y='40%' text-anchor='middle'>",unicode'⚾️',"</text><text font-size='5em' x='50%' y='70%' text-anchor='middle'>Words</text><text font-size='3em' x='50%' y='90%' text-anchor='middle'>#", _contracts.tokenUri.uint2str(tokenIndex), " / ", _contracts.tokenUri.uint2str(maxSupply), "</text></g></svg>")
        );

    }








    /**
       PROJECT
     */

    uint256 private _projectNonce = 0;

    uint256 private _burnFeeSum = 0;


    uint256[] public projectIds;

    function getProject(uint256 projectId) public view returns (Project memory) {
        return _mappings.projects[projectId];
    }

    function projectAttributeCategories(uint256 projectId) public view returns (uint256[] memory c) {
        return _mappings.projects[projectId].attributeCategoryIds;
    }

    function projectCount() public view returns (uint256) {
        return _projectNonce;
    }





    /**
       ATTRIBUTE PROBABILITIES
     */


    function getAttributeProbabilities(uint256 projectId, uint256 attributeCategoryId) public view returns (AttributeProbability[] memory _attrProb) {
        return _mappings.attributeProbabilities[projectId][attributeCategoryId];
    }


    function validProject(uint256 projectId) view public {
        //Validate the project exists.
        require(projectId > 0, "Invalid project id");
        require(_mappings.projects[projectId].id == projectId, "Invalid project");
    }

    function _createProjectAttributes(uint256 projectId, uint256[] memory attributeCategoryIds, uint256[][] memory attributeProbabilities) private {

        for (uint256 i=0; i < attributeProbabilities.length; i++) {

            uint256 categoryId = attributeCategoryIds[i];

            //Make sure category exists
            require(bytes(_contracts.words.word(categoryId)).length > 0, "Invalid attribute category");


            uint256[] memory row = attributeProbabilities[i];

            uint probabilityTotal = 0;
            uint lastProbability = 0;

            //Validate
            //Odd indexes are attribute ids. Look one index further to get the probability.
            //Probabilities need to be loaded in ascending order
            for (uint256 j=0; j < row.length; j+=2) {

                uint256 attributeId = row[j];
                uint256 probability = row[j+1];

                require(bytes(_contracts.words.word(attributeId)).length > 0, "Invalid attribute");
                require(probability > 0, "Invalid probability");
                require(probability >= lastProbability, "Descending probability");

                probabilityTotal += probability;
                lastProbability = probability;

            }

            require(probabilityTotal == 1000000, "Invalid probability total");

            //Push AttributeProbability to storage
            for (uint256 j=0; j < row.length; j+=2) {
                _mappings.attributeProbabilities[projectId][categoryId].push(AttributeProbability(row[j], row[j+1]));
            }


        }

    }






}