// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./ERC721Enumerable.sol";

import "./IXSublimatio.sol";

contract XSublimatio is IXSublimatio, ERC721Enumerable {

    using Strings for uint256;

    // Contains first 21 molecule availabilities (12 bits each).
    uint256 internal COMPACT_STATE_1 = uint256(60087470205620319587750252891185586116542855063423969629534558109603704138);

    // Contains next 42 molecule availabilities (6 bits each).
    uint256 internal COMPACT_STATE_2 = uint256(114873104402099400223353432978706708436353982610412083425164130989245597730);

    // Contains (right to left) 19 drug availabilities (8 bits each), total drugs available (11 bits), total molecules available (13 bits), and nonce (remaining 80 bits).
    uint256 internal COMPACT_STATE_3 = uint256(67212165445492353831982701316699907697777805738906362);

    uint256 public immutable LAUNCH_TIMESTAMP;

    address public owner;
    address public pendingOwner;
    address public proceedsDestination;

    bytes32 public assetGeneratorHash;

    string public baseURI;

    uint256 public pricePerTokenMint;

    mapping(address => bool) internal _canClaimFreeWater;

    constructor (
        string memory baseURI_,
        address owner_,
        uint256 pricePerTokenMint_,
        uint256 launchTimestamp_
    ) ERC721("XSublimatio", "XSUB") {
        baseURI = baseURI_;
        owner = owner_;
        pricePerTokenMint = pricePerTokenMint_;
        LAUNCH_TIMESTAMP = launchTimestamp_;
    }

    modifier onlyAfterLaunch() {
        require(block.timestamp >= LAUNCH_TIMESTAMP, "NOT_LAUNCHED_YET");
        _;
    }

    modifier onlyBeforeLaunch() {
        require(block.timestamp < LAUNCH_TIMESTAMP, "ALREADY_LAUNCHED");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "UNAUTHORIZED");

        _;
    }

    /***********************/
    /*** Admin Functions ***/
    /***********************/

    function acceptOwnership() external {
        require(pendingOwner == msg.sender, "UNAUTHORIZED");

        emit OwnershipAccepted(owner, msg.sender);
        owner = msg.sender;
        pendingOwner = address(0);
    }

    function proposeOwnership(address newOwner_) external onlyOwner {
        emit OwnershipProposed(owner, pendingOwner = newOwner_);
    }

    function setAssetGeneratorHash(bytes32 assetGeneratorHash_) external onlyOwner {
        require(assetGeneratorHash == bytes32(0) || block.timestamp < LAUNCH_TIMESTAMP, "ALREADY_LAUNCHED");
        emit AssetGeneratorHashSet(assetGeneratorHash = assetGeneratorHash_);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        emit BaseURISet(baseURI = baseURI_);
    }

    function setPricePerTokenMint(uint256 pricePerTokenMint_) external onlyOwner onlyBeforeLaunch {
        emit PricePerTokenMintSet(pricePerTokenMint = pricePerTokenMint_);
    }

    function setProceedsDestination(address proceedsDestination_) external onlyOwner {
        require(proceedsDestination == address(0) || block.timestamp < LAUNCH_TIMESTAMP, "ALREADY_LAUNCHED");
        emit ProceedsDestinationSet(proceedsDestination = proceedsDestination_);
    }

    function setPromotionAccounts(address[] memory accounts_) external onlyOwner onlyBeforeLaunch {
        for (uint256 i; i < accounts_.length;) {
            address account = accounts_[i];
            _canClaimFreeWater[account] = true;
            emit PromotionAccountSet(account);

            unchecked {
                ++i;
            }
        }
    }

    function unsetPromotionAccounts(address[] memory accounts_) external onlyOwner onlyBeforeLaunch {
        for (uint256 i; i < accounts_.length;) {
            address account = accounts_[i];
            _canClaimFreeWater[account] = false;
            emit PromotionAccountUnset(account);

            unchecked {
                ++i;
            }
        }
    }

    function withdrawProceeds() external {
        uint256 amount = address(this).balance;
        address destination = proceedsDestination;
        destination = destination == address(0) ? owner : destination;

        require(_transferEther(destination, amount), "ETHER_TRANSFER_FAILED");
        emit ProceedsWithdrawn(destination, amount);
    }

    /**************************/
    /*** External Functions ***/
    /**************************/

    function brew(uint256[] calldata molecules_, uint256 drugType_, address destination_) external onlyAfterLaunch returns (uint256 drug_) {
        // Check that drugType_ is valid.
        require(drugType_ < 19, "INVALID_DRUG_TYPE");

        // Cache relevant compact state from storage.
        uint256 compactState3 = COMPACT_STATE_3;

        // Check that drug is available.
        require(_getDrugAvailability(compactState3, drugType_) != 0, "DRUG_NOT_AVAILABLE");

        uint256 specialWater;

        unchecked {
            // The specific special water moleculeType for this drug is 44 more than the drugType.
            specialWater = drugType_ + 44;
        }

        // Fetch the recipe from the pure function.
        uint8[] memory recipe = getRecipeOfDrug(drugType_);

        uint256 index;

        // For each moleculeType defined by the recipe, check that the provided moleculeType at that index is as expected, or the special water.
        while (index < recipe.length) {
            uint256 molecule = molecules_[index];

            // Check that the caller owns the token.
            require(ownerOf(molecule) == msg.sender, "NOT_OWNER");

            // Extract molecule type from token id.
            uint256 moleculeType = molecule >> 93;

            // Check that the molecule type matches what the recipe calls for, or the molecule is the special water.
            require(moleculeType == specialWater || recipe[index] == moleculeType, "INVALID_MOLECULE");

            unchecked {
                ++index;
            }
        }

        index = 0;

        address drugAsAddress = address(uint160(drug_ = _generateTokenId(drugType_ + 63, _generatePseudoRandomNumber(_getTokenNonce(compactState3)))));

        // Make the drug itself own all the molecules used.
        while (index < recipe.length) {
            uint256 molecule = molecules_[index];

            // Transfer the molecule.
            _transfer(msg.sender, drugAsAddress, molecule);

            unchecked {
                ++index;
            }
        }

        // Put token type as the leftmost 8 bits in the token id and mint the drug NFT (drugType + 63).
        _mint(destination_, drug_);

        // Decrement it's availability, decrement the total amount of drugs available, and increment the drug nonce, and set storage.
        COMPACT_STATE_3 = _decrementDrugAvailability(compactState3, drugType_);
    }

    function claimWater(address destination_) external returns (uint256 molecule_) {
        // NOTE: no need for the onlyBeforeLaunch modifier since `canClaimFreeWater` already checks the timestamp
        require(canClaimFreeWater(msg.sender), "CANNOT_CLAIM");

        _canClaimFreeWater[msg.sender] = false;

        ( COMPACT_STATE_1, COMPACT_STATE_2, COMPACT_STATE_3, molecule_ ) = _giveMolecule(COMPACT_STATE_1, COMPACT_STATE_2, COMPACT_STATE_3, 0, destination_);
    }

    function decompose(uint256 drug_) external {
        // NOTE: no need for onlyAfterLaunch modifier because drug cannot exist (be brewed) before launch, nor can water be burned before launch.
        // Check that the caller owns the token.
        require(ownerOf(drug_) == msg.sender, "NOT_OWNER");

        uint256 drugType = (drug_ >> 93);

        // Check that the token is a drug.
        require(drugType >= 63 && drugType < 82, "NOT_DRUG");

        unchecked {
            drugType -= 63;
        }

        address drugAsAddress = address(uint160(drug_));
        uint256 moleculeCount = balanceOf(drugAsAddress);

        for (uint256 i = moleculeCount; i > 0;) {
            uint256 molecule = tokenOfOwnerByIndex(drugAsAddress, --i);

            if (i == 0) {
                // Burn the water (which should be the first token).
                _burn(molecule);
                continue;
            }

            // Transfer the molecule to the owner.
            _transfer(drugAsAddress, msg.sender, molecule);
        }

        // Increment the drugs' availability, increment the total amount of drugs available, and set storage.
        COMPACT_STATE_3 = _incrementDrugAvailability(COMPACT_STATE_3, drugType);

        // Burn the drug.
        _burn(drug_);
    }

    function giveWaters(address[] memory destinations_, uint256[] memory amounts_) external onlyOwner onlyBeforeLaunch {
        // Cache relevant compact states from storage.
        uint256 compactState1 = COMPACT_STATE_1;
        uint256 compactState2 = COMPACT_STATE_2;
        uint256 compactState3 = COMPACT_STATE_3;

        for (uint256 i; i < destinations_.length;) {
            for (uint256 j; j < amounts_[i];) {
                ( compactState1, compactState2, compactState3, ) = _giveMolecule(compactState1, compactState2, compactState3, 0, destinations_[i]);

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        // Set relevant storage state fromm the cache ones.
        COMPACT_STATE_1 = compactState1;
        COMPACT_STATE_2 = compactState2;
        COMPACT_STATE_3 = compactState3;
    }

    function giveMolecules(address[] memory destinations_, uint256[] memory amounts_) external onlyOwner onlyBeforeLaunch {
        require(block.timestamp < LAUNCH_TIMESTAMP, "ALREADY_LAUNCHED");

        // Cache relevant compact states from storage.
        uint256 compactState1 = COMPACT_STATE_1;
        uint256 compactState2 = COMPACT_STATE_2;
        uint256 compactState3 = COMPACT_STATE_3;

        // Get the number of molecules available from compactState3.
        uint256 availableMoleculeCount = _getMoleculesAvailable(compactState3);

        for (uint256 i; i < destinations_.length;) {
            for (uint256 j; j < amounts_[i];) {
                // Get a pseudo random number.
                uint256 randomNumber = _generatePseudoRandomNumber(_getTokenNonce(compactState3));
                uint256 moleculeType;

                // Provide _drawMolecule with the 3 relevant cached compact states, and a random number between 0 and availableMoleculeCount - 1, inclusively.
                // The result is newly updated cached compact states. Also, availableMoleculeCount is pre-decremented so that each random number is within correct bounds.
                ( compactState1, compactState2, compactState3, moleculeType ) = _drawMolecule(compactState1, compactState2, compactState3, _limitTo(randomNumber, --availableMoleculeCount));

                // Generate a token id from the moleculeType and randomNumber (saving it in the array of token IDs) and mint the molecule NFT.
                _mint(destinations_[i], _generateTokenId(moleculeType, randomNumber));

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        // Set relevant storage state fromm the cache ones.
        COMPACT_STATE_1 = compactState1;
        COMPACT_STATE_2 = compactState2;
        COMPACT_STATE_3 = compactState3;
    }

    function purchase(address destination_, uint256 quantity_, uint256 minQuantity_) external payable onlyAfterLaunch returns (uint256[] memory molecules_) {
        // Cache relevant compact states from storage.
        uint256 compactState1 = COMPACT_STATE_1;
        uint256 compactState2 = COMPACT_STATE_2;
        uint256 compactState3 = COMPACT_STATE_3;

        // Get the number of molecules available from compactState3 and determine how many molecules will be purchased in this call.
        uint256 availableMoleculeCount = _getMoleculesAvailable(compactState3);
        uint256 count = availableMoleculeCount >= quantity_ ? quantity_ : availableMoleculeCount;

        // Prevent a purchase fo 0 nfts, as well as a purchase of less nfts than the user expected.
        require(count != 0, "NO_MOLECULES_AVAILABLE");
        require(count >= minQuantity_, "CANNOT_FULLFIL_REQUEST");

        // Compute the price this purchase will cost, since it will be needed later, and count will be decremented in a while-loop.
        uint256 totalCost;
        unchecked {
            totalCost = pricePerTokenMint * count;
        }

        // Require that enough ether was provided,
        require(msg.value >= totalCost, "INCORRECT_VALUE");

        if (msg.value > totalCost) {
            // If extra, require that it is successfully returned to the caller.
            unchecked {
                require(_transferEther(msg.sender, msg.value - totalCost), "TRANSFER_FAILED");
            }
        }

        // Initialize the array of token IDs to a length of the nfts to be purchased.
        molecules_ = new uint256[](count);

        while (count > 0) {
            // Get a pseudo random number.
            uint256 randomNumber = _generatePseudoRandomNumber(_getTokenNonce(compactState3));
            uint256 moleculeType;

            unchecked {
                // Provide _drawMolecule with the 3 relevant cached compact states, and a random number between 0 and availableMoleculeCount - 1, inclusively.
                // The result is newly updated cached compact states. Also, availableMoleculeCount is pre-decremented so that each random number is within correct bounds.
                ( compactState1, compactState2, compactState3, moleculeType ) = _drawMolecule(compactState1, compactState2, compactState3, _limitTo(randomNumber, --availableMoleculeCount));

                // Generate a token id from the moleculeType and randomNumber (saving it in the array of token IDs) and mint the molecule NFT.
                _mint(destination_, molecules_[--count] = _generateTokenId(moleculeType, randomNumber));
            }
        }

        // Set relevant storage state fromm the cache ones.
        COMPACT_STATE_1 = compactState1;
        COMPACT_STATE_2 = compactState2;
        COMPACT_STATE_3 = compactState3;
    }

    /***************/
    /*** Getters ***/
    /***************/

    function availabilities() external view returns (uint256[63] memory moleculesAvailabilities_, uint256[19] memory drugAvailabilities_) {
        moleculesAvailabilities_ = moleculeAvailabilities();
        drugAvailabilities_ = drugAvailabilities();
    }

    function canClaimFreeWater(address account_) public view returns (bool canClaimFreeWater_) {
        return block.timestamp < LAUNCH_TIMESTAMP && _canClaimFreeWater[account_];
    }

    function compactStates() external view returns (uint256 compactState1_, uint256 compactState2_, uint256 compactState3_) {
        return (COMPACT_STATE_1, COMPACT_STATE_2, COMPACT_STATE_3);
    }

    function contractURI() external view returns (string memory contractURI_) {
        return baseURI;
    }

    function drugAvailabilities() public view returns (uint256[19] memory availabilities_) {
        // Cache relevant compact states from storage.
        uint256 compactState3 = COMPACT_STATE_3;

        for (uint256 i; i < 19;) {
            availabilities_[i] = _getDrugAvailability(compactState3, i);

            unchecked {
                ++i;
            }
        }

    }

    function drugsAvailable() external view returns (uint256 drugsAvailable_) {
        drugsAvailable_ = _getDrugsAvailable(COMPACT_STATE_3);
    }

    function getAvailabilityOfDrug(uint256 drugType_) external view returns (uint256 availability_) {
        availability_ = _getDrugAvailability(COMPACT_STATE_3, drugType_);
    }

    function getAvailabilityOfMolecule(uint256 moleculeType_) external view returns (uint256 availability_) {
        availability_ = _getMoleculeAvailability(COMPACT_STATE_1, COMPACT_STATE_2, moleculeType_);
    }

    function getDrugContainingMolecule(uint256 molecule_) external view returns (uint256 drug_) {
        drug_ = uint256(uint160(ownerOf(molecule_)));
    }

    function getMoleculesWithinDrug(uint256 drug_) external view returns (uint256[] memory molecules_) {
        molecules_ = tokensOfOwner(address(uint160(drug_)));
    }

    function getRecipeOfDrug(uint256 drugType_) public pure returns (uint8[] memory recipe_) {
        if (drugType_ <= 7) {
            recipe_ = new uint8[](2);

            recipe_[1] =
                drugType_ == 0 ? 1 :  // Alcohol (Isolated)
                drugType_ == 1 ? 33 : // Chloroquine (Isolated)
                drugType_ == 2 ? 8 :  // Cocaine (Isolated)
                drugType_ == 3 ? 31 : // GHB (Isolated)
                drugType_ == 4 ? 15 : // Ketamine (Isolated)
                drugType_ == 5 ? 32 : // LSD (Isolated)
                drugType_ == 6 ? 2 :  // Methamphetamine (Isolated)
                14;                   // Morphine (Isolated)
        } else if (drugType_ == 16) {
            recipe_ = new uint8[](3);

            // Mate
            recipe_[1] = 3;
            recipe_[2] = 4;
        } else if (drugType_ == 11 || drugType_ == 12) {
            recipe_ = new uint8[](4);

            if (drugType_ == 11) { // Khat
                recipe_[1] = 5;
                recipe_[2] = 6;
                recipe_[3] = 7;
            } else {               // Lactuca Virosa
                recipe_[1] = 19;
                recipe_[2] = 20;
                recipe_[3] = 21;
            }
        } else if (drugType_ == 14 || drugType_ == 15 || drugType_ == 17) {
            recipe_ = new uint8[](5);

            if (drugType_ == 14) {        // Magic Truffle
                recipe_[1] = 25;
                recipe_[2] = 26;
                recipe_[3] = 27;
                recipe_[4] = 28;
            } else if (drugType_ == 15) { // Mandrake
                recipe_[1] = 16;
                recipe_[2] = 17;
                recipe_[3] = 18;
                recipe_[4] = 34;
            } else {                      // Opium
                recipe_[1] = 14;
                recipe_[2] = 22;
                recipe_[3] = 23;
                recipe_[4] = 24;
            }
        } else if (drugType_ == 9 || drugType_ == 10 || drugType_ == 18) {
            recipe_ = new uint8[](6);

            if (drugType_ == 9) {         // Belladonna
                recipe_[1] = 16;
                recipe_[2] = 17;
                recipe_[3] = 18;
                recipe_[4] = 29;
                recipe_[5] = 30;
            } else if (drugType_ == 10) { // Cannabis
                recipe_[1] = 9;
                recipe_[2] = 10;
                recipe_[3] = 11;
                recipe_[4] = 12;
                recipe_[5] = 13;
            } else {                      // Salvia Divinorum
                recipe_[1] = 35;
                recipe_[2] = 36;
                recipe_[3] = 40;
                recipe_[4] = 41;
                recipe_[5] = 42;
            }
        } else if (drugType_ == 8) {
            recipe_ = new uint8[](7);

            // Ayahuasca
            recipe_[1] = 8;
            recipe_[2] = 37;
            recipe_[3] = 38;
            recipe_[4] = 39;
            recipe_[5] = 43;
            recipe_[6] = 44;
        } else if (drugType_ == 13) {
            recipe_ = new uint8[](9);

            // Love Elixir
            recipe_[1] = 9;
            recipe_[2] = 45;
            recipe_[3] = 46;
            recipe_[4] = 47;
            recipe_[5] = 48;
            recipe_[6] = 49;
            recipe_[7] = 50;
            recipe_[8] = 51;
        } else {
            revert("INVALID_RECIPE");
        }

        // All recipes require Water, so recipe_[0] remains 0.
    }

    function moleculesAvailable() external view returns (uint256 moleculesAvailable_) {
        moleculesAvailable_ = _getMoleculesAvailable(COMPACT_STATE_3);
    }

    function moleculeAvailabilities() public view returns (uint256[63] memory availabilities_) {
        // Cache relevant compact states from storage.
        uint256 compactState1 = COMPACT_STATE_1;
        uint256 compactState2 = COMPACT_STATE_2;

        for (uint256 i; i < 63;) {
            availabilities_[i] = _getMoleculeAvailability(compactState1, compactState2, i);

            unchecked {
                ++i;
            }
        }
    }

    function tokensOfOwner(address owner_) public view returns (uint256[] memory tokenIds_) {
        uint256 balance = balanceOf(owner_);

        tokenIds_ = new uint256[](balance);

        for (uint256 i; i < balance;) {
            tokenIds_[i] = tokenOfOwnerByIndex(owner_, i);

            unchecked {
                ++i;
            }
        }
    }

    function tokenURI(uint256 tokenId_) public override view returns (string memory tokenURI_) {
        require(_exists(tokenId_), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURICache = baseURI;

        tokenURI_ = bytes(baseURICache).length > 0 ? string(abi.encodePacked(baseURICache, "/", tokenId_.toString())) : "";
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function _beforeTokenTransfer(address from_, address to_, uint256 tokenId_) internal override {
        // Can mint before launch, but transfers and burns can only happen after launch.
        require(from_ == address(0) || block.timestamp >= LAUNCH_TIMESTAMP, "NOT_LAUNCHED_YET");
        super._beforeTokenTransfer(from_, to_, tokenId_);
    }

    function _clearBits(uint256 input_, uint256 mask_, uint256 shift_) internal pure returns (uint256 output_) {
        // Clear out bits in input with mask.
        output_ = (input_ & ~(mask_ << shift_));
    }

    function _constrainBits(uint256 input_, uint256 mask_, uint256 shift_, uint256 max_) internal pure returns (uint256 output_) {
        // Clear out bits in input with mask, and replace them with the removed bits constrained to some max.
        output_ = _clearBits(input_, mask_, shift_) | ((((input_ >> shift_) & mask_) % max_) << shift_);
    }

    function _decrementDrugAvailability(uint256 compactState3_, uint256 drugType_) internal pure returns (uint256 newCompactState3_) {
        unchecked {
            // Increment the token nonce, which is located left of 19 8-bit individual drug availabilities, an 11-bit total drug availability, and a 13-bit total molecule availability.
            // Decrement the total drug availability, which is located left of 19 8-bit individual drug availabilities.
            // Decrement the corresponding availability of a specific drug.
            // Clearer: newCompactState3_ = compactState4_
            //            + (1 << (19 * 8 + 11 + 13))
            //            - (1 << (19 * 8))
            //            - (1 << (drugType_ * 8));
            newCompactState3_ = compactState3_ + 95780965595127282823557164963750446178190649605488640 - (1 << (drugType_ * 8));
        }
    }

    function _decrementMoleculeAvailability(
        uint256 compactState1_,
        uint256 compactState2_,
        uint256 compactState3_,
        uint256 moleculeType_
    ) internal pure returns (uint256 newCompactState1_, uint256 newCompactState2_, uint256 newCompactState3_) {
        unchecked {
            // Increment the token nonce, which is located left of 19 8-bit individual drug availabilities, an 11-bit total drug availability, and a 13-bit total molecule availability.
            // Decrement the total molecule availability, which is located left of 19 8-bit individual drug availabilities and an 11-bit total drug availability.
            // Clearer: compactState3_ = compactState3_
            //            + (1 << (19 * 8 + 11 + 13))
            //            - (1 << (19 * 8 + 11));
            compactState3_ = compactState3_ + 95769279291019406424051059718232593712013947676131328;

            // Decrement the corresponding availability of a specific molecule, in a compact state given the molecule type.
            if (moleculeType_ < 21) return (compactState1_ - (1 << (moleculeType_ * 12)), compactState2_, compactState3_);

            return (compactState1_, compactState2_ - (1 << ((moleculeType_ - 21) * 6)), compactState3_);
        }
    }

    function _drawMolecule(
        uint256 compactState1_,
        uint256 compactState2_,
        uint256 compactState3_,
        uint256 randomNumber_
    ) internal pure returns (uint256 newCompactState1_, uint256 newCompactState2_, uint256 newCompactState3_, uint256 moleculeType_) {
        uint256 offset;

        while (moleculeType_ < 63) {
            unchecked {
                // Increment the offset by the availability of the molecule defined by moleculeType, and break if randomNumber is less than it.
                if (randomNumber_ < (offset += _getMoleculeAvailability(compactState1_, compactState2_, moleculeType_))) break;

                // If not (i.e. randomNumber does not corresponding to picking moleculeType), increment the moleculeType and try again.
                ++moleculeType_;
            }
        }

        // Decrement the availability of this molecule, decrement the total amount of available molecules, and increment some molecule nonce.
        // Give this pure function the relevant cached compact states and get back updated compact states.
        ( newCompactState1_, newCompactState2_, newCompactState3_ ) = _decrementMoleculeAvailability(compactState1_, compactState2_, compactState3_, moleculeType_);
    }

    function _generatePseudoRandomNumber(uint256 nonce_) internal view returns (uint256 pseudoRandomNumber_) {
        unchecked {
            pseudoRandomNumber_ = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, nonce_, gasleft())));
        }
    }

    function _generateTokenId(uint256 type_, uint256 pseudoRandomNumber_) internal pure returns (uint256 tokenId_) {
        // In right-most 100 bits, first 7 bits are the type and last 93 bits are from the pseudo random number.
        tokenId_ = (type_ << 93) | (pseudoRandomNumber_ >> 163);

        // From right to left:
        //  - 32 bits are to be used as an unsigned 32-bit (or signed 32-bit) seed.
        //  - 16 bits are to be used as an unsigned 16-bit for brt.
        //  - 16 bits are to be used as an unsigned 16-bit for sat.
        //  - 16 bits are to be used as an unsigned 16-bit for hue.

        if (type_ > 62) {
            tokenId_ = _clearBits(tokenId_, 1, 32 + 16 + 16 + 16);
            tokenId_ = _clearBits(tokenId_, 3, 32 + 16 + 16 + 16 + 1);
        } else {
            //  - 1 bit is to be used for 2 lighting types.
            tokenId_ = _constrainBits(tokenId_, 1, 32 + 16 + 16 + 16, 2);

            //  - 2 bits are to be used for 4 molecule integrity types.
            tokenId_ = _constrainBits(tokenId_, 3, 32 + 16 + 16 + 16 + 1, 4);
        }

        //  - 2 bits are to be used for 3 deformation types.
        tokenId_ = _constrainBits(tokenId_, 3, 32 + 16 + 16 + 16 + 1 + 2, 3);

        //  - 1 bit is to be used for 2 color shift types.
        tokenId_ = _constrainBits(tokenId_, 1, 32 + 16 + 16 + 16 + 1 + 2 + 2, 2);

        //  - 2 bits are to be used for 3 stripe amount types.
        tokenId_ = _constrainBits(tokenId_, 3, 32 + 16 + 16 + 16 + 1 + 2 + 2 + 1, 3);

        //  - 2 bits are to be used for 3 blob types.
        tokenId_ = _constrainBits(tokenId_, 3, 32 + 16 + 16 + 16 + 1 + 2 + 2 + 1 + 2, 3);

        //  - 3 bits are to be used for 6 palette types.
        tokenId_ = _constrainBits(tokenId_, 7, 32 + 16 + 16 + 16 + 1 + 2 + 2 + 1 + 2 + 2, 6);
    }

    function _getDrugAvailability(uint256 compactState3_, uint256 drugType_) internal pure returns (uint256 availability_) {
        unchecked {
            availability_ = (compactState3_ >> (drugType_ * 8)) & 255;
        }
    }

    function _getDrugsAvailable(uint256 compactState3_) internal pure returns (uint256 drugsAvailable_) {
        // Shift out 19 8-bit values (19 drug availabilities) from the right of the compact state, and mask as 11 bits.
        drugsAvailable_ = (compactState3_ >> 152) & 2047;
    }

    function _getMoleculeAvailability(
        uint256 compactState1_,
        uint256 compactState2_,
        uint256 moleculeType_
    ) internal pure returns (uint256 availability_) {
        unchecked {
            if (moleculeType_ < 21) return (compactState1_ >> (moleculeType_ * 12)) & 4095;

            return (compactState2_ >> ((moleculeType_ - 21) * 6)) & 63;
        }
    }

    function _getMoleculesAvailable(uint256 compactState3_) internal pure returns (uint256 moleculesAvailable_) {
        // Shift out 19 8-bit values (19 drug availabilities) and an 11-bit value (total drugs available), and mask as 13 bits.
        moleculesAvailable_ = (compactState3_ >> 163) & 8191;
    }

    function _getTokenNonce(uint256 compactState3_) internal pure returns (uint256 moleculeNonce_) {
        // Shift out 19 8-bit values (19 drug availabilities), an 11-bit value (total drugs available), and a 13-bit value (total molecules available).
        moleculeNonce_ = compactState3_ >> 176;
    }

    function _giveMolecule(
        uint256 compactState1_,
        uint256 compactState2_,
        uint256 compactState3_,
        uint256 moleculeType_,
        address destination_
    ) internal returns (uint256 newCompactState1_, uint256 newCompactState2_, uint256 newCompactState3_, uint256 molecule_) {
        require(_getMoleculeAvailability(compactState1_, compactState2_, moleculeType_) > 0, "NO_AVAILABILITY");

        // Get a pseudo random number.
        uint256 randomNumber = _generatePseudoRandomNumber(_getTokenNonce(compactState3_));

        // Decrement the availability of the molecule, decrement the total amount of available molecules, and increment some molecule nonce.
        // Give this pure function the relevant cached compact states and get back updated compact states.
        // Set relevant storage state fromm the cache ones.
        ( newCompactState1_, newCompactState2_, newCompactState3_ ) = _decrementMoleculeAvailability(compactState1_, compactState2_, compactState3_, moleculeType_);

        // Generate a token id from the moleculeType and randomNumber (saving it in the array of token IDs) and mint the molecule NFT.
        _mint(destination_, molecule_ = _generateTokenId(moleculeType_, randomNumber));
    }

    function _incrementDrugAvailability(uint256 compactState3_, uint256 drugType_) internal pure returns (uint256 newCompactState3_) {
        unchecked {
            // Increment the total drug availability, which is located left of 19 8-bit individual drug availabilities.
            // Increment the corresponding availability of a specific drug.
            // Clearer: newCompactState3_ = compactState3_
            //            + (1 << (19 * 8))
            //            + (1 << (drugType_ * 8));
            newCompactState3_ = compactState3_ + 5708990770823839524233143877797980545530986496 + (1 << (drugType_ * 8));
        }
    }

    function _limitTo(uint256 input_, uint256 max_) internal pure returns (uint256 output_) {
        output_ = 0 == max_ ? 0 : input_ % (max_ + 1);
    }

    function _transferEther(address destination_, uint256 amount_) internal returns (bool success_) {
        ( success_, ) = destination_.call{ value: amount_ }("");
    }

}
