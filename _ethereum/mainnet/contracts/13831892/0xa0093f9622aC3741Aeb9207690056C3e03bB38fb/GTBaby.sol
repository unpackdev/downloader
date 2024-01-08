//Tes-sal
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./IERC721Enumerable.sol";
import "./Counters.sol";
import "./IERC20.sol";
import "./Strings.sol";

contract Gleaf {
    function getGiraffeLendFee(uint256 token_id)
        public
        view
        returns (uint256)
    {}

    function getStaker(uint256 tokenId) public view returns (address) {}
}

contract GTBaby is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    event Mint(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed collectionId
    );
    event Collection(
        uint256 indexed collection_id,
        string indexed collection_name
    );
    event NameChange(uint256 tokenId, string name);
    struct Incubator {
        uint256 parentId1;
        uint256 parentId2;
        uint256 childId;
        uint256 revealTime;
        uint256 collectionId;
        address initiatorAddress;
        uint256 incubationStart;
    }
    struct collectionBaseConfig {
        string collection_name;
        uint256 start_time;
        uint256 end_time;
        uint256 max_supply;
        bool early_access;
        address collection_address;
        uint256 total_minted;
        bool status;
        uint256 min_balance;
    }
    struct collectionWaitPeriodConfig {
        uint256 incubation_period;
        uint256 wait_period;
        uint256 staked_incubation_period;
        uint256 staked_wait_period;
    }
    struct collectionFeeConfig {
        uint256 staked_fee;
        uint256 unstaked_fee;
        uint256 staked_fast_incubation_fee;
        uint256 unstaked_fast_incubation_fee;
        uint256 staked_fast_availability_fee;
        uint256 unstaked_fast_availability_fee;
    }
    struct lastBreed {
        uint256 tokenId;
        uint256 availableTime;
    }
    mapping(string => lastBreed) public collectionToLastBreedTime;
    mapping(uint256 => Incubator) public tokenIdToIncubator;
    mapping(uint256 => uint256) public giraffeToOfffspring;
    mapping(uint256 => collectionBaseConfig) public collection_details;
    mapping(uint256 => collectionWaitPeriodConfig) public collectionWaitPeriods;
    mapping(uint256 => collectionFeeConfig) public collectionFees;
    mapping(string => bool) private _nameReserved;
    address public giraffetowerAddress =
        0xb487A91382cD66076fc4C1AF4D7d8CE7f929A9bA;
    address public gleafAddress = 0x55a23fB10506B2679d0C53b4468309c7105fB16f;
    address nullAddress = 0x0000000000000000000000000000000000000000;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    address private ownerAddress;
    string _currentBaseURI = "https://api.giraffetowernft.com/baby/";
    uint256 public nameChangePrice = 10 ether;
    address pr = 0x044780Ef6d06BF528c03f423bF3D9d8a88837A3f;
    mapping(uint256 => string) giraffeName;

    constructor() ERC721("GTBaby", "GTBaby") {
        ownerAddress = msg.sender;
    }

    function setGiraffeName(uint256 tokenId, string memory name) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "Token is not nameable by you!"
        );
        require(validateName(name) == true, "Not a valid new name");
        require(
            sha256(bytes(name)) != sha256(bytes(giraffeName[tokenId])),
            "New name is same as the current one"
        );
        require(isNameReserved(name) == false, "Name already reserved");
        uint256 allowance = IERC20(gleafAddress).allowance(
            msg.sender,
            address(this)
        );
        require(allowance >= nameChangePrice, "Check the token allowance");
        IERC20(gleafAddress).transferFrom(
            msg.sender,
            address(this),
            nameChangePrice
        );
        if (pr != address(this)) {
            IERC20(gleafAddress).transfer(pr, nameChangePrice);
        }

        if (bytes(giraffeName[tokenId]).length > 0) {
            toggleReserveName(giraffeName[tokenId], false);
        }
        toggleReserveName(name, true);
        giraffeName[tokenId] = name;
        emit NameChange(tokenId, name);
    }

    function setPr(address _address) public onlyOwner {
        pr = _address;
    }

    /**
     * @dev Reserves the name if isReserve is set to true, de-reserves if set to false
     */
    function toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[toLower(str)] = isReserve;
    }

    function isNameReserved(string memory nameString)
        public
        view
        returns (bool)
    {
        return _nameReserved[toLower(nameString)];
    }

    function validateName(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 1) return false;
        if (b.length > 25) return false; // Cannot be longer than 25 characters
        if (b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            ) return false;

            lastChar = char;
        }

        return true;
    }

    /**
     * @dev Converts the string to lowercase
     */
    function toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function getGiraffeName(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return giraffeName[tokenId];
    }

    function changeNamePrice(uint256 _price) external onlyOwner {
        nameChangePrice = _price;
    }

    function setGiraffetowerAddress(address _giraffetowerAddress)
        public
        onlyOwner
    {
        giraffetowerAddress = _giraffetowerAddress;
        return;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _currentBaseURI = baseURI;
    }

    function setGleafAddress(address _gleafAddress) public onlyOwner {
        gleafAddress = _gleafAddress;
        return;
    }

    function initiateCollection(
        uint256 collection_id,
        string memory collection_name,
        uint256 start_time,
        uint256 end_time,
        uint256 max_supply,
        address collection_address,
        bool status,
        bool early_access,
        uint256 min_balance
    ) public onlyOwner {
        collection_details[collection_id].start_time =
            block.timestamp +
            (start_time * 1 days);
        collection_details[collection_id].collection_name = collection_name;
        collection_details[collection_id].end_time =
            block.timestamp +
            (end_time * 1 days);
        collection_details[collection_id].max_supply = max_supply;
        collection_details[collection_id]
            .collection_address = collection_address;
        collection_details[collection_id].status = status;
        collection_details[collection_id].early_access = early_access;
        collection_details[collection_id].min_balance = min_balance;
        emit Collection(collection_id, collection_name);
    }

    function setWaitPeriods(
        uint256 collection_id,
        uint256 wait_period,
        uint256 incubation_period,
        uint256 staked_incubation_period,
        uint256 staked_wait_period
    ) public onlyOwner {
        collectionWaitPeriods[collection_id]
            .incubation_period = incubation_period;
        collectionWaitPeriods[collection_id].wait_period = wait_period;
        collectionWaitPeriods[collection_id]
            .staked_incubation_period = staked_incubation_period;
        collectionWaitPeriods[collection_id]
            .staked_wait_period = staked_wait_period;
    }

    function setCollectionFees(
        uint256 collection_id,
        uint256 staked_fee,
        uint256 unstaked_fee,
        uint256 staked_fast_incubation_fee,
        uint256 unstaked_fast_incubation_fee,
        uint256 staked_fast_availability_fee,
        uint256 unstaked_fast_availability_fee
    ) public onlyOwner {
        collectionFees[collection_id].staked_fee = staked_fee;
        collectionFees[collection_id].unstaked_fee = unstaked_fee;
        collectionFees[collection_id]
            .staked_fast_incubation_fee = staked_fast_incubation_fee;
        collectionFees[collection_id]
            .unstaked_fast_incubation_fee = unstaked_fast_incubation_fee;
        collectionFees[collection_id]
            .staked_fast_availability_fee = staked_fast_availability_fee;
        collectionFees[collection_id]
            .unstaked_fast_availability_fee = unstaked_fast_availability_fee;
    }

    function setCollectionMW(
        uint256 collection_id,
        uint256 minimum_balance,
        address collection_address
    ) public onlyOwner {
        collection_details[collection_id].min_balance = minimum_balance;
        collection_details[collection_id]
            .collection_address = collection_address;
    }

    function setBreedingStatus(uint256 collection_id, bool status)
        public
        onlyOwner
    {
        collection_details[collection_id].status = status;
    }

    function setCollectionName(
        uint256 collection_id,
        string memory _collection_name
    ) public onlyOwner {
        collection_details[collection_id].collection_name = _collection_name;
    }

    function setBreedingEarlyAccess(uint256 collection_id, bool status)
        public
        onlyOwner
    {
        collection_details[collection_id].early_access = status;
    }

    function initiateBreeding(
        uint256 collection_id,
        uint256 _parentId1,
        uint256 _parentId2
    ) public {
        Gleaf glf = Gleaf(gleafAddress);
        require(
            msg.sender == tx.origin,
            "Contracts not allowed to initiateBreeding"
        );

        require(
            collection_details[collection_id].status == true,
            "Breeding is not active."
        );
        require(
            collection_details[collection_id].start_time <= block.timestamp,
            "Breeding is has not started."
        );
        require(
            collection_details[collection_id].end_time > block.timestamp,
            "Breeding is has ended."
        );
        if (collection_details[collection_id].early_access == true) {
            //check if both parentId are staked;
            require(
                glf.getStaker(_parentId1) != nullAddress,
                "Only Staked Giraffe Can Breed Currently"
            );
            require(
                glf.getStaker(_parentId2) != nullAddress,
                "Only Staked Giraffe Can Breed Currently"
            );
        }
        if (collection_details[collection_id].min_balance > 0) {
            //check if both parentId are staked;
            require(
                IERC20(gleafAddress).balanceOf(msg.sender) >=
                    collection_details[collection_id].min_balance,
                "CCMBNA"
            );
        }
        require(
            collection_details[collection_id].total_minted <
                collection_details[collection_id].max_supply,
            "Max supply reached!"
        );
        string memory catid1 = string(
            abi.encodePacked(
                Strings.toString(collection_id),
                Strings.toString(_parentId1)
            )
        );
        string memory catid2 = string(
            abi.encodePacked(
                Strings.toString(collection_id),
                Strings.toString(_parentId2)
            )
        );

        require(
            collectionToLastBreedTime[catid1].availableTime <= block.timestamp,
            "Parent1 not available!"
        );
        require(
            collectionToLastBreedTime[catid2].availableTime <= block.timestamp,
            "Parent2 not available!"
        );
        uint256[] memory _parentIdrentfee = new uint256[](2);
        address[] memory _parentIdowner = new address[](2);
        _parentIdrentfee[0] = 0;
        _parentIdrentfee[1] = 0;
        _parentIdowner[0] = nullAddress;
        _parentIdowner[1] = nullAddress;
        //Require they are the owners of both parents.
        if (IERC721(giraffetowerAddress).ownerOf(_parentId1) != msg.sender) {
            _parentIdowner[0] = glf.getStaker(_parentId1);
            require(_parentIdowner[0] != nullAddress, "You Don't own giraffe1");
            if (_parentIdowner[0] != msg.sender) {
                _parentIdrentfee[0] = glf.getGiraffeLendFee(_parentId1);
                require(_parentIdrentfee[0] > 0, "Giraffe1 Not for Rent");
            }
        }
        if (IERC721(giraffetowerAddress).ownerOf(_parentId2) != msg.sender) {
            _parentIdowner[1] = glf.getStaker(_parentId2);
            require(_parentIdowner[1] != nullAddress, "You Don't own giraffe2");
            if (_parentIdowner[1] != msg.sender) {
                _parentIdrentfee[1] = glf.getGiraffeLendFee(_parentId2);
                require(_parentIdrentfee[1] > 0, "Giraffe2 Not for Rent");
            }
        }
        uint256 total_rent = _parentIdrentfee[0] + _parentIdrentfee[1];
        uint256 breedingFee;
        uint256 incubation_period;
        uint256 wait_period;
        if (
            _parentIdowner[0] != nullAddress && _parentIdowner[1] != nullAddress
        ) {
            breedingFee = collectionFees[collection_id].staked_fee;
            incubation_period = collectionWaitPeriods[collection_id]
                .staked_incubation_period;
            wait_period = collectionWaitPeriods[collection_id]
                .staked_wait_period;
        } else {
            breedingFee = collectionFees[collection_id].unstaked_fee;
            incubation_period = collectionWaitPeriods[collection_id]
                .incubation_period;
            wait_period = collectionWaitPeriods[collection_id].wait_period;
        }
        uint256 total_fee = total_rent + breedingFee;
        require(
            IERC20(gleafAddress).allowance(msg.sender, address(this)) >=
                total_fee,
            "Check the token allowance"
        );
        require(
            IERC20(gleafAddress).balanceOf(msg.sender) >= total_fee,
            "Insufficient Balance"
        );
        IERC20(gleafAddress).transferFrom(msg.sender, address(this), total_fee);
        if (_parentIdrentfee[0] > 0) {
            IERC20(gleafAddress).transfer(
                _parentIdowner[0],
                _parentIdrentfee[0]
            );
        }
        if (_parentIdrentfee[1] > 0) {
            IERC20(gleafAddress).transfer(
                _parentIdowner[1],
                _parentIdrentfee[1]
            );
        }
        uint256[] memory parent_ids = new uint256[](2);
        uint256[] memory others = new uint256[](3);
        parent_ids[0] = _parentId1;
        parent_ids[1] = _parentId2;
        others[0] = breedingFee;
        others[1] = wait_period;
        others[2] = incubation_period;
        processBreeding(collection_id, parent_ids, others);
    }

    function processBreeding(
        uint256 collection_id,
        uint256[] memory parent_ids,
        uint256[] memory others
    ) internal {
        if (
            collection_details[collection_id].collection_address !=
            address(this)
        ) {
            IERC20(gleafAddress).transfer(
                collection_details[collection_id].collection_address,
                others[0]
            );
        }
        uint256 _tokenId = totalSupply();
        string memory catid1 = string(
            abi.encodePacked(
                Strings.toString(collection_id),
                Strings.toString(parent_ids[0])
            )
        );
        string memory catid2 = string(
            abi.encodePacked(
                Strings.toString(collection_id),
                Strings.toString(parent_ids[1])
            )
        );
        collectionToLastBreedTime[catid1] = lastBreed(
            parent_ids[0],
            block.timestamp + (others[1] * 1 hours)
        );
        collectionToLastBreedTime[catid2] = lastBreed(
            parent_ids[1],
            block.timestamp + (others[1] * 1 hours)
        );
        tokenIdToIncubator[_tokenId] = Incubator(
            parent_ids[0],
            parent_ids[1],
            _tokenId,
            block.timestamp + (others[2] * 1 hours),
            collection_id,
            msg.sender,
            block.timestamp
        );
        collection_details[collection_id].total_minted += 1;
        giraffeToOfffspring[parent_ids[0]] += 1;
        giraffeToOfffspring[parent_ids[1]] += 1;
        //Mint them their unrevealed baby
        emit Mint(msg.sender, _tokenId, collection_id);
        _mint(msg.sender, _tokenId);
    }

    function speedUpParentAvailability(uint256 _collectionId, uint256 _tokenId)
        public
    {
        Gleaf glf = Gleaf(gleafAddress);
        string memory catid1 = string(
            abi.encodePacked(
                Strings.toString(_collectionId),
                Strings.toString(_tokenId)
            )
        );
        require(
            collectionToLastBreedTime[catid1].availableTime > block.timestamp,
            "Token id Supplied is available."
        );
        uint256 speedUpFee;
        if (glf.getStaker(_tokenId) != nullAddress) {
            speedUpFee = collectionFees[_collectionId]
                .staked_fast_availability_fee;
        } else {
            speedUpFee = collectionFees[_collectionId]
                .unstaked_fast_availability_fee;
        }
        uint256 allowance = IERC20(gleafAddress).allowance(
            msg.sender,
            address(this)
        );
        require(allowance >= speedUpFee, "Check the token allowance");
        require(
            IERC20(gleafAddress).balanceOf(msg.sender) >= speedUpFee,
            "Insufficient Balance"
        );
        IERC20(gleafAddress).transferFrom(
            msg.sender,
            address(this),
            speedUpFee
        );
        if (
            collection_details[_collectionId].collection_address !=
            address(this)
        ) {
            IERC20(gleafAddress).transfer(
                collection_details[_collectionId].collection_address,
                speedUpFee
            );
        }
        collectionToLastBreedTime[catid1].availableTime = block.timestamp;
    }

    function speedUpChildReveal(uint256 _tokenId, uint256 _collectionId)
        public
    {
        Gleaf glf = Gleaf(gleafAddress);
        require(
            tokenIdToIncubator[_tokenId].revealTime > block.timestamp,
            "Child Already Revealed"
        );
        uint256 speedUpFee;
        if (
            glf.getStaker(tokenIdToIncubator[_tokenId].parentId1) !=
            nullAddress &&
            glf.getStaker(tokenIdToIncubator[_tokenId].parentId2) != nullAddress
        ) {
            speedUpFee = collectionFees[_collectionId]
                .staked_fast_incubation_fee;
        } else {
            speedUpFee = collectionFees[_collectionId]
                .unstaked_fast_incubation_fee;
        }
        uint256 allowance = IERC20(gleafAddress).allowance(
            msg.sender,
            address(this)
        );
        require(allowance >= speedUpFee, "Check the token allowance");
        require(
            IERC20(gleafAddress).balanceOf(msg.sender) >= speedUpFee,
            "Insufficient Balance"
        );
        IERC20(gleafAddress).transferFrom(
            msg.sender,
            address(this),
            speedUpFee
        );
        if (
            collection_details[_collectionId].collection_address !=
            address(this)
        ) {
            IERC20(gleafAddress).transfer(
                collection_details[_collectionId].collection_address,
                speedUpFee
            );
        }
        //Set the new reveal time.
        tokenIdToIncubator[_tokenId].revealTime = block.timestamp;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    function getParents(uint256 tokenId)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory Parents = new uint256[](2);
        Parents[0] = tokenIdToIncubator[tokenId].parentId1;
        Parents[1] = tokenIdToIncubator[tokenId].parentId2;
        return Parents;
    }

    function isAvailable(uint256 tokenId, uint256 collectionId)
        public
        view
        returns (bool)
    {
        string memory catid1 = string(
            abi.encodePacked(
                Strings.toString(collectionId),
                Strings.toString(tokenId)
            )
        );
        if (
            collectionToLastBreedTime[catid1].availableTime <= block.timestamp
        ) {
            return true;
        } else {
            return false;
        }
    }

    function getRevealTime(uint256 tokenId) public view returns (uint256) {
        return tokenIdToIncubator[tokenId].revealTime;
    }

    function isRevealed(uint256 tokenId) public view returns (bool) {
        if (tokenIdToIncubator[tokenId].revealTime <= block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory base = _baseURI();

        return
            string(abi.encodePacked(base, Strings.toString(tokenId), ".json"));
    }

    function withdrawFunds(uint256 amount) public onlyOwner {
        sendEth(ownerAddress, amount);
    }

    function sendEth(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Failed to send ether");
    }

    function withdrawToken(
        IERC20 token,
        address recipient,
        uint256 amount
    ) public onlyOwner {
        require(
            token.balanceOf(address(this)) >= amount,
            "You do not have sufficient Balance"
        );
        token.transfer(recipient, amount);
    }
}
