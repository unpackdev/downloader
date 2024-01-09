// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;




///  _           _   _         _    _                                         _     
/// | |_ ___ ___| |_|_|___ ___| |  | |_ ___ ___ ___ ___ ___ _____ ___        |_|___ 
/// |  _| .'|  _|  _| |  _| .'| |  |  _| .'|   | . |  _| .'|     |_ -|   _   | | . |
/// |_| |__,|___|_| |_|___|__,|_|  |_| |__,|_|_|_  |_| |__,|_|_|_|___|  |_|  |_|___|
///                                            |___|                                
///
///                                                              tacticaltangrams.io




///  _                   _       
/// |_|_____ ___ ___ ___| |_ ___ 
/// | |     | . | . |  _|  _|_ -|
/// |_|_|_|_|  _|___|_| |_| |___|
///         |_|                  

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

import "./State.sol";
import "./Team.sol";
import "./VRFD20.sol";




///  _     _           ___                 
/// |_|___| |_ ___ ___|  _|___ ___ ___ ___ 
/// | |   |  _| -_|  _|  _| .'|  _| -_|_ -|
/// |_|_|_|_| |___|_| |_| |__,|___|___|___|

interface TangramContract {
    function getGeneration(uint tokenId) external pure returns (uint);
    function getTanMetadata(uint tokenId, uint generation, uint generationSeed) external pure returns (string memory);
}




///              _               _      _____         
///  ___ ___ ___| |_ ___ ___ ___| |_   |_   _|___ ___ 
/// |  _| . |   |  _|  _| .'|  _|  _|    | | | .'|   |
/// |___|___|_|_|_| |_| |__,|___|_|      |_| |__,|_|_|                                                  

/// @title Tactical Tangrams main Tan contract
/// @author tacticaltangrams.io
/// @notice Tracks all Tan operations for tacticaltangrams.io. This makes this contract the OpenSea Tan collection
contract Tan is
    ERC721Enumerable,
    Ownable,
    Pausable,
    State,
    Team,
    VRFD20 {




    /// @notice Emit Generation closing event; triggered by swapping 80+ Tans for the current generation
    /// @param generation Generation that is closing
    event GenerationClosing(uint generation);

    /// @notice Emit Generation closed event
    /// @param generation Generation that is closed
    event GenerationClosed(uint generation);




    ///                  _               _           
    ///  ___ ___ ___ ___| |_ ___ _ _ ___| |_ ___ ___ 
    /// |  _| . |   |_ -|  _|  _| | |  _|  _| . |  _|
    /// |___|___|_|_|___|_| |_| |___|___|_| |___|_|  

    /// @notice Deployment constructor
    /// @param _name                    ERC721 name of token
    /// @param _symbol                  ERC721 symbol of token
    /// @param _openPremintAtDeployment Opens premint directly at contract deployment
    /// @param _vrfCoordinator          Chainlink VRF Coordinator address
    /// @param _link                    LINK token address
    /// @param _keyHash                 Public key against which randomness is created
    /// @param _fee                     VRF Chainlink fee in LINK
    /// @param _teamAddresses           List of team member's addresses; first address is emergency address
    /// @param _tangramContract         Address for Tangram contract
    constructor(
            address payable[TEAM_SIZE] memory _teamAddresses,
            string memory                     _name,
            string memory                     _symbol,
            bool                              _openPremintAtDeployment,
            address                           _vrfCoordinator,
            address                           _link,
            bytes32                           _keyHash,
            uint                              _fee,
            address                           _tangramContract
        )

        ERC721(
            _name,
            _symbol
        )

        Team(
            _teamAddresses
        )

        VRFD20(
            _vrfCoordinator,
            _link,
            _keyHash,
            _fee
        )
    {
        vrfCoordinator = _vrfCoordinator;
        setTangramContract(_tangramContract);

        if (_openPremintAtDeployment)
        {
            changeState(
                StateType.DEPLOYED,
                StateType.PREMINT);
        }
    }




    ///        _     _   
    ///  _____|_|___| |_ 
    /// |     | |   |  _|
    /// |_|_|_|_|_|_|_|  

    uint constant public MAX_MINT         = 15554;
    uint constant public MAX_TANS_OG      = 7;
    uint constant public MAX_TANS_WL      = 7;
    uint constant public MAX_TANS_PUBLIC  = 14;

    uint constant public PRICE_WL         = 2 * 1e16;
    uint constant public PRICE_PUBLIC     = 3 * 1e16;

    bytes32 private merkleRootOG = 0x67a345396a56431c46add239308b6fcfbab7dbf09287447d3f5f2458c0cccdc5;
    bytes32 private merkleRootWL = 0xf6c54efaf65ac33f79611e973313be91913aaf019de02d6d3ae1e6566f75929a;

    mapping (address => bool) private addressPreminted;
    mapping (uint    => uint) public mintCounter;

    string private constant INVALID_NUMBER_OF_TANS = "Invalid number of tans or no more tans left";

    /// @notice Get maximum number of mints for the given generation
    /// @param generation Generation to get max mints for
    /// @return Maximum number of mints for generation
    function maxMintForGeneration(uint generation) public pure
        generationBetween(generation, 1, 7)
        returns (uint)
    {
        if (generation == 7) {
            return 55;
        }
        if (generation == 6) {
            return 385;
        }
        if (generation == 5) {
            return 980;
        }
        if (generation == 4) {
            return 2310;
        }
        if (generation == 3) {
            return 5005;
        }
        if (generation == 2) {
            return 9156;
        }

        return MAX_MINT;
    }


    /// @notice Get number of mints for the given generation for closing announcement
    /// @param generation Generation to get max mints for
    /// @return Maximum number of mints for generation
    function maxMintForGenerationBeforeClosing(uint generation) public pure
        generationBetween(generation, 2, 6)
        returns (uint)
    {
        if (generation == 6) {
            return 308;
        }
        if (generation == 5) {
            return 784;
        }
        if (generation == 4) {
            return 1848;
        }
        if (generation == 3) {
            return 4004;
        }

        return 7325;
    }


    /// @notice Get the lowest Tan ID for a given generation
    /// @param generation Generation to get lowest ID for
    /// @return Lowest Tan ID for generation
    function mintStartNumberForGeneration(uint generation) public pure
        generationBetween(generation, 1, 7)
        returns (uint)
    {
        uint tmp = 1;
        for (uint gen = 1; gen <= 7; gen++) {
            if (generation == gen) {
                return tmp;
            }
            tmp += maxMintForGeneration(gen);
        }

        return 0;
    }


    /// @notice Public mint method. Checks whether the paid price is correct and max. 14 Tans are minted per tx
    /// @param numTans number of Tans to mint
    function mint(uint numTans) external payable
        forPrice(numTans, PRICE_PUBLIC, msg.value)
        inState(StateType.MINT)
        limitTans(numTans, MAX_TANS_PUBLIC)
    {
        mintLocal(numTans);
    }


    /// @notice Mint helper method
    /// @dev All checks need to be performed before calling this method
    /// @param numTans number of Tans to mint
    function mintLocal(uint numTans) private
        inEitherState(StateType.PREMINT, StateType.MINT)
        whenNotPaused()
    {
        for (uint mintedTan = 0; mintedTan < numTans; mintedTan++) {
            _mint(_msgSender(), totalSupply() + 1);
        }        
    }


    /// @notice Mint next-gen Tans at Tangram swap
    /// @param numTans number of Tans to mint
    /// @param _for Address to mint Tans for
    function mintForNextGeneration(uint numTans, address _for) external
        generationBetween(currentGeneration, 1, 6)
        inStateOrAbove(StateType.GENERATIONSTARTED)
        onlyTangramContract()
        whenNotPaused()
    {
        uint nextGeneration = currentGeneration + 1;

        uint maxMintForNextGeneration = maxMintForGeneration(nextGeneration);

        require(
            mintCounter[nextGeneration] + numTans <= maxMintForNextGeneration,
            INVALID_NUMBER_OF_TANS
        );

        for (uint mintedTan = 0; mintedTan < numTans; mintedTan++) {
            _mint(
                _for,
                mintStartNumberForGeneration(nextGeneration) + mintCounter[nextGeneration]++
            );
        }
    }


    /// @notice OG mint method. Allowed once per OG minter, OG proof is by merkle proof. Max 7 Tans allowed
    /// @dev Method is not payable since OG mint for free
    /// @param merkleProof Merkle proof of minter address for OG tree
    /// @param numTans     Number of Tans to mint
    function mintOG(bytes32[] calldata merkleProof, uint numTans) external
        inEitherState(StateType.PREMINT, StateType.MINT)
        isValidMerkleProof(merkleRootOG, merkleProof)
        limitTans(numTans, MAX_TANS_OG)
        oneMint()
    {
        addressPreminted[_msgSender()] = true;
        mintLocal(numTans);
    }


    /// @notice WL mint method. Allowed once per WL minter, WL proof is by merkle proof. Max 7 Tans allowed
    /// @param merkleProof Merkle proof of minter address for WL tree
    /// @param numTans     Number of Tans to mint
    function mintWL(bytes32[] calldata merkleProof, uint numTans) external payable
        forPrice(numTans, PRICE_WL, msg.value)
        inEitherState(StateType.PREMINT, StateType.MINT)
        isValidMerkleProof(merkleRootWL, merkleProof)
        limitTans(numTans, MAX_TANS_WL)
        oneMint()
    {
        addressPreminted[_msgSender()] = true;
        mintLocal(numTans);
    }


    /// @notice Update merkle roots for OG/WL minters
    /// @param og OG merkle root
    /// @param wl WL merkle root
    function setMerkleRoot(bytes32 og, bytes32 wl) external
        onlyOwner()
    {
        merkleRootOG = og;
        merkleRootWL = wl;
    }


    /// @notice Require correct paid price
    /// @dev WL and public mint pay a fixed price per Tan
    /// @param numTans   Number of Tans to mint
    /// @param unitPrice Fixed price per Tan
    /// @param ethSent   Value of ETH sent in this transaction
    modifier forPrice(uint numTans, uint unitPrice, uint ethSent) {
        require(
            numTans * unitPrice == ethSent,
            "Wrong value sent"
        );
        _;
    }


    /// @notice Verify provided merkle proof to given root
    /// @dev Root is manually generated before contract deployment. Proof is automatically provided by minting site based on connected wallet address.
    /// @param root  Merkle root to verify against
    /// @param proof Merkle proof to verify
    modifier isValidMerkleProof(bytes32 root, bytes32[] calldata proof) {
        require(
            MerkleProof.verify(proof, root, keccak256(abi.encodePacked(_msgSender()))),
            "Invalid proof"
        );
        _;
    }


    /// @notice Require a valid number of Tans
    /// @param numTans Number of Tans to mint
    /// @param maxTans Maximum number of Tans to allow
    modifier limitTans(uint numTans, uint maxTans) {
        require(
            numTans >= 1 &&
            numTans <= maxTans &&
            totalSupply() + numTans <= MAX_MINT,
            INVALID_NUMBER_OF_TANS
        );
        _;
    }


    /// @notice Require maximum one mint per address
    /// @dev OG and WL minters have this restriction
    modifier oneMint() {
        require(
            addressPreminted[_msgSender()] == false,
            "Only one premint allowed"
        );
        _;
    }




    ///      _       _       
    ///  ___| |_ ___| |_ ___ 
    /// |_ -|  _| .'|  _| -_|
    /// |___|_| |__,|_| |___|                     

    /// @notice Change to mint stage; this is an implicit action when "mint" is called when shouldPublicMintBeOpen == true
    /// @dev Can only be called over Chainlink VRF random response
    function changeStateGenerationClosed() internal virtual override
        generationBetween(currentGeneration, 1, 7)
        inEitherState(StateType.GENERATIONSTARTED, StateType.GENERATIONCLOSING)
        onlyTeamMemberOrOwner()
    {
        if (currentGeneration < 7) {
            lastGenerationSeedRequestTimestamp = 0;
            requestGenerationSeed(currentGeneration + 1);
        }

        emit GenerationClosed(currentGeneration);
    }


    /// @notice Change to mint stage; this is an implicit action when "mint" is called when shouldPublicMintBeOpen == true
    /// @dev Can only be called over Chainlink VRF random response
    function changeStateGenerationClosing() internal virtual override
        inState(StateType.GENERATIONSTARTED)
        onlyTangramContract()
    {
        emit GenerationClosing(currentGeneration);
    }


    /// @notice Change to mint stage; this is an implicit action when "mint" is called when shouldPublicMintBeOpen == true
    /// @dev Can only be called over Chainlink VRF random response
    function changeStateGenerationStarted() internal virtual override
        inEitherState(StateType.MINTCLOSED, StateType.GENERATIONCLOSED)
        onlyVRFCoordinator()
    {
    }


    /// @notice Change to mint stage; this is an implicit action when "mint" is called when shouldPublicMintBeOpen == true
    /// @dev Can also be called over setState method
    function changeStateMint() internal virtual override
        inState(StateType.PREMINT)
        onlyTeamMemberOrOwner()
    {
    }


    /// @notice Request Gen-1 seed, payout caller's funds
    /// @dev Caller's funds are only paid when this method was invoked from a team member's address; not the owner's address
    function changeStateMintClosed() internal virtual override
        inState(StateType.MINT)
        onlyTeamMemberOrOwner()
    {
        requestGenerationSeed(1);
    }


    /// @notice Request Gen-1 seed, payout caller's funds
    /// @dev Caller's funds are only paid when this method was invoked from a team member's address; not the owner's address
    function changeStateMintClosedAfter() internal virtual override
        inState(StateType.MINTCLOSED)
        onlyTeamMemberOrOwner()
    {
        mintCounter[1] = totalSupply();
        mintBalanceTotal = address(this).balance - secondaryBalanceTotal;
        if (!emergencyCalled && isTeamMember(_msgSender()) && address(this).balance > 0)
        {
            payout();
        }
    }


    /// @notice Change to premint stage
    /// @dev This is only allowed by the contract owner, either by means of deployment or later execution of setState
    function changeStatePremint() internal virtual override
        inState(StateType.DEPLOYED)
        onlyTeamMemberOrOwner()
    {
    }


    /// @notice Set new state
    /// @dev Use this for non-automatic state changes (e.g. open premint, close generation)
    /// @param _to New state to change to
    function setState(StateType _to) external
        onlyTeamMemberOrOwner()
    {
        changeState(state, _to);
    }


    /// @notice Announce generation close
    function setStateGenerationClosing() external
        onlyTangramContract()
    {
        changeState(state, StateType.GENERATIONCLOSING);
    }




    ///                _                           
    ///  ___ ___ ___ _| |___ _____ ___ ___ ___ ___ 
    /// |  _| .'|   | . | . |     |   | -_|_ -|_ -|
    /// |_| |__,|_|_|___|___|_|_|_|_|_|___|___|___|

    address private immutable vrfCoordinator;

    /// @notice Generation seed received, open generation
    /// @dev Only possibly when mint is closed or previous generation has been closed. Seed is in VRFD20.generationSeed[generation]. Event is NOT emitted from contract address.
    /// @param generation Generation for which seed has been received
    function processGenerationSeedReceived(uint generation) internal virtual override
        inEitherState(StateType.MINTCLOSED, StateType.GENERATIONCLOSED)
        onlyVRFCoordinator()
    {
        require(
            generation == currentGeneration + 1,
            "Invalid seed generation"
        );

        currentGeneration = generation;

        state = StateType.GENERATIONSTARTED;

        // Emitting stateChanged event is useless, as this is in the VRF Coordinator's tx context
    }


    /// @notice Re-request generation seed
    /// @dev Only possible before starting new generation. Requests seed for the next generation. Important checks performed by internal method.
    function reRequestGenerationSeed() external
        inEitherState(StateType.MINT, StateType.GENERATIONCLOSED)
        onlyTeamMemberOrOwner()
    {
        requestGenerationSeed(currentGeneration + 1);
    }


    /// @notice Require that the sender is Chainlink's VRF Coordinator
    modifier onlyVRFCoordinator() {
        require(
            _msgSender() == vrfCoordinator,
            "Only VRF Coordinator"
        );
        _;
    }




    ///                      _   
    ///  ___ ___ _ _ ___ _ _| |_ 
    /// | . | .'| | | . | | |  _|
    /// |  _|__,|_  |___|___|_|  
    /// |_|     |___|            

    string private constant TX_FAILED = "TX failed";

    /// @notice Pay out all funds directly to the emergency wallet
    /// @dev Only emergency payouts can be used; personal payouts are locked
    function emergencyPayout() external
        onlyTeamMemberOrOwner()
    {
        emergencyCalled = true;
        (bool sent,) = teamAddresses[0].call{value: address(this).balance}("");
        require(
            sent,
            TX_FAILED
        );
    }


    /// @notice Pay the yet unpaid funds to the caller, when it is a team member
    /// @dev Does not work after emergency payout was used. Implement secondary share payouts
    function payout() public
        emergencyNotCalled()
        inStateOrAbove(StateType.MINTCLOSED)
    {
        (bool isTeamMember, uint teamIndex) = getTeamIndex(_msgSender());
        require(
            isTeamMember,
            "Invalid address"
        );

        uint shareIndex = teamIndex * TEAM_SHARE_RECORD_SIZE;

        uint mintShare = 0;
        if (mintSharePaid[teamIndex] == false) {
            mintSharePaid[teamIndex] = true;
            mintShare = (mintBalanceTotal * teamShare[shareIndex + TEAM_SHARE_MINT_OFFSET]) / 1000;
        }
        
        uint secondaryShare = 0;
        if (secondaryBalanceTotal > teamShare[shareIndex + TEAM_SHARE_SECONDARY_PAID_OFFSET]) {
            uint secondaryShareToPay = secondaryBalanceTotal - teamShare[shareIndex + TEAM_SHARE_SECONDARY_PAID_OFFSET];
            teamShare[shareIndex + TEAM_SHARE_SECONDARY_PAID_OFFSET] = secondaryBalanceTotal;
            secondaryShare = (secondaryShareToPay * teamShare[shareIndex + TEAM_SHARE_SECONDARY_OFFSET]) / 1000;
        }

        uint total = mintShare + secondaryShare;
        require(
            total > 0,
            "Nothing to pay"
        );

        (bool sent,) = payable(_msgSender()).call{value: total}("");
        require(
            sent,
            TX_FAILED
        );
    }


    /// @notice Keep track of total secondary sales earnings
    receive() external payable
    {
        secondaryBalanceTotal += msg.value;
    }


    /// @notice Require emergency payout to not have been called
    modifier emergencyNotCalled() {
        require(
            false == emergencyCalled,
            "Emergency called"
        );
        _;
    }



    ///              ___ ___ ___   
    ///  ___ ___ ___|_  |_  |_  |  
    /// | -_|  _|  _| | |  _|_| |_ 
    /// |___|_| |___| |_|___|_____|


    /// @notice Burn token on behalf of Tangram contract
    /// @dev Caller needs to verify token ownership
    /// @param tokenId Token ID to burn
    function burn(uint256 tokenId) external 
        onlyTangramContract()
        whenNotPaused()
    {
        _burn(tokenId);
    }


    /// @notice Return metadata url (placeholder) or base64-encoded metadata when gen-1 has started
    /// @dev Overridden from OpenZeppelin's implementation to skip the unused baseURI check
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "Nonexistent token"
        );
        
        if (state <= StateType.MINTCLOSED)
        {
            return string(abi.encodePacked(
                METADATA_BASE_URI,
                "placeholder",
                JSON_EXT
            ));
        }

        uint generation = tangramContract.getGeneration(tokenId);
        require(
            generation <= currentGeneration,
            INVALID_GENERATION
        );

        return tangramContract.getTanMetadata(tokenId, generation, generationSeed[generation]);
    }




    ///            _         _     _       
    ///  _____ ___| |_ ___ _| |___| |_ ___ 
    /// |     | -_|  _| .'| . | .'|  _| .'|
    /// |_|_|_|___|_| |__,|___|__,|_| |__,|

    function contractURI() public pure returns (string memory) {
        return string(abi.encodePacked(
            METADATA_BASE_URI,
            METADATA_CONTRACT,
            JSON_EXT
        ));
    }




    ///                          _ 
    ///  ___ ___ ___ ___ ___ ___| |
    /// | . | -_|   | -_|  _| .'| |
    /// |_  |___|_|_|___|_| |__,|_|
    /// |___|                      

    uint private mintBalanceTotal      = 0;
    uint private secondaryBalanceTotal = 0;
    uint public  currentGeneration     = 0;

    string private constant METADATA_BASE_URI = 'https://tacticaltangrams.io/metadata/';
    string private constant METADATA_CONTRACT = 'contract_tan';
    string private constant JSON_EXT          = '.json';

    string private constant INVALID_GENERATION = "Invalid generation";
    string private constant ONLY_TEAM_MEMBER   = "Only team member";

    modifier generationBetween(uint generation, uint from, uint to) {
        require(
            generation >= from && generation <= to,
            INVALID_GENERATION
        );
        _;
    }

    /// @notice Require that the sender is a team member
    modifier onlyTeamMember() {
        require(
            isTeamMember(_msgSender()),
            ONLY_TEAM_MEMBER
        );
        _;
    }


    /// @notice Require that the sender is a team member or the contract owner
    modifier onlyTeamMemberOrOwner() {
        require(
            _msgSender() == owner() || isTeamMember(_msgSender()),
            string(abi.encodePacked(ONLY_TEAM_MEMBER, " or owner"))
        );
        _;
    }




    ///              _               _      _____                           
    ///  ___ ___ ___| |_ ___ ___ ___| |_   |_   _|___ ___ ___ ___ ___ _____ 
    /// |  _| . |   |  _|  _| .'|  _|  _|    | | | .'|   | . |  _| .'|     |
    /// |___|___|_|_|_| |_| |__,|___|_|      |_| |__,|_|_|_  |_| |__,|_|_|_|
    ///                                                  |___|                      

    TangramContract tangramContract;
    address tangramContractAddress;

    /// @notice Set Tangram contract address
    /// @param _tangramContract Address for Tangram contract
    function setTangramContract(address _tangramContract) public
        onlyOwner()
    {
        tangramContractAddress = _tangramContract;
        tangramContract = TangramContract(_tangramContract);
    }


    /// @notice Require that the sender is the Tangram contract
    modifier onlyTangramContract() {
        require(
            _msgSender() == tangramContractAddress,
            "Only Tangram contract"
        );
        _;
    }
}
