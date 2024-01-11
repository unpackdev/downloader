//  _                    _      _             _
// | |                  | |    | |           | |
// | |      ___    ___  | | __ | |      __ _ | |__   ___
// | |     / _ \  / _ \ | |/ / | |     / _` || '_ \ / __|
// | |____| (_) || (_) ||   <  | |____| (_| || |_) |\__ \
// \_____/ \___/  \___/ |_|\_\ \_____/ \__,_||_.__/ |___/
//
//
// Gift Card
//
// by LOOK LABS
//
// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.8.4;

import "./ERC1155Burnable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

contract LLTicket is ERC1155Burnable, ReentrancyGuard, Ownable, Pausable {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    uint256 public constant MINT_LIMIT = 1;
    string public constant NAME = "LOOK LABS Ticket";
    string public constant SYMBOL = "LLTicket";

    string private _baseTokenURI;
    address private _validator;

    uint256 public tokenCount;

    mapping(uint256 => uint256) public supplies;
    mapping(bytes => bool) public isMintedSig;
    mapping(uint256 => uint256) public supplyCaps;

    /* ==================== EVENTS ==================== */

    event Initialized(string tokenURI, address validator);
    event Mint(address indexed user, address to, uint256 tokenId);

    /* ==================== METHODS ==================== */

    /**
     * @dev Initialize the contract by setting baseUri.
     *
     * @param _tokenURI Base URI for metadata
     * @param _account Validator address
     */
    constructor(string memory _tokenURI, address _account) ERC1155(_tokenURI) {
        _baseTokenURI = _tokenURI;
        _validator = _account;

        tokenCount = 7;
        supplyCaps[0] = 300; // $50
        supplyCaps[1] = 2000; // $100
        supplyCaps[2] = 1000; // $200
        supplyCaps[3] = 750; // $420
        supplyCaps[4] = 500; // $1000
        supplyCaps[5] = 200; // $5000
        supplyCaps[6] = 50; // $10000

        emit Initialized(_baseTokenURI, _validator);
    }

    /**
     * @dev This function allows to mint G1 Bud.
     *      The id should be generated and sent from off-chain backend.
     * @param _to Address to be sent the minted token
     * @param _id Token id to mint
     * @param _timestamp Timestamp to verify the signature
     * @param _signature Signature is generated from LL backend.
     */
    function mint(
        address _to,
        uint256 _id,
        uint256 _timestamp,
        bytes memory _signature
    ) external whenNotPaused {
        require(_id >= 0 && _id < tokenCount, "Invalid token id");
        require(_verify(_to, _id, _timestamp, _signature), "Not verified");
        require(supplies[_id] + MINT_LIMIT <= supplyCaps[_id], "Reached max supply");
        require(!isMintedSig[_signature], "Already minted");

        supplies[_id] += MINT_LIMIT;
        isMintedSig[_signature] = true;
        _mint(_to, _id, MINT_LIMIT, "");

        emit Mint(_msgSender(), _to, _id);
    }

    /**
     * @param _id Gift card type id
     */
    function uri(uint256 _id) public view override returns (string memory) {
        require(_id < tokenCount, "URI requested for invalid token type");

        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_id)));
    }

    /* ==================== INTERNAL METHODS ==================== */

    /**
     * @dev Verify if the signature is right and available to mint
     *
     * @param _to Address to be sent the minted token
     * @param _id Token id to mint
     * @param _timestamp Timestamp to verify the signature
     * @param _signature Signature is generated from LL backend.
     */
    function _verify(
        address _to,
        uint256 _id,
        uint256 _timestamp,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 signedHash = keccak256(abi.encodePacked(_to, keccak256("Ticket"), _id, MINT_LIMIT, _timestamp));
        bytes32 messageHash = signedHash.toEthSignedMessageHash();
        address messageSender = messageHash.recover(_signature);

        if (messageSender != _validator) return false;

        return true;
    }

    /* ==================== GETTER METHODS ==================== */

    /**
     * @dev The function checks if the token is minted or not
     *
     * @param _signature Signature is generated from LL backend.
     */
    function isMinted(bytes memory _signature) external view returns (bool) {
        if (isMintedSig[_signature]) return true;
        return false;
    }

    /* ==================== OWNER METHODS ==================== */

    /**
     * @dev Owner can set the validator address
     *
     * @param _account The validator address
     */
    function setValidator(address _account) external onlyOwner {
        _validator = _account;
    }

    /**
     * @dev Owner can update the max token count and its token supplies
     *
     * @param _caps Array of 3 game item capacities
     */
    function setTokenSupplies(uint256 _count, uint256[] memory _caps) external onlyOwner {
        require(_count > 0 && _count >= tokenCount, "Supply increase only allowed");
        require(_caps.length == _count, "Invalid supply caps");

        for (uint256 i = 0; i < _count; i++) {
            require(_caps[i] >= supplies[i], "Supply increase only allowed");
            supplyCaps[i] = _caps[i];
        }
        tokenCount = _count;
    }

    /**
     * @dev Owner can set the base uri
     *
     * @param baseURI Base URI for metadata
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Owner can pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Owner can unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
