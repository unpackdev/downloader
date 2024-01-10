// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC1155.sol";
import "./IERC1155.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./Base58.sol";

contract NftArtForUkraine is ERC2981, IERC1155, ERC1155, ReentrancyGuard, Ownable {
    using Strings for bytes;

    string private _uri;
    string private _contractMetadataURI;

    uint256 public minPrice = 5*10**16; //0.05ETH

    bool public mintEnabled = false;

    address public artManager;
    uint256 public totalCollected;

    uint256 public idCounter;
    mapping(uint256 => uint256) public totalSupply;
    mapping(uint256 => uint256) public maxSupply;
    mapping(uint256 => bool) public mintEnabledId;
    mapping(uint256 => bytes32) public idHash;

    bool public autoForward = true;
    mapping(address => bool) public approvedRecipients;
    address[] public approvedRecipientsList;

    event NewMinPrice(uint256 oldPrice, uint256 newPrice);
    event Forwarded(address to, uint256 amount);
    event NewArt(uint256 id, bytes hash);
    event Rescued(address token, uint256 amount, address to);
    event MintingEnabled(bool enable);
    event MintingEnabledId(uint256 id, bool enable);
    event Contributed(address from, uint256 amount);

    constructor(string memory uri_, string memory contractMetadataURI) ERC1155(uri_) {
        artManager = msg.sender;
        _uri = uri_;
        _contractMetadataURI = contractMetadataURI;
        address recipient = 0x1D45c8fa65F6b18E7dAe04b2efEa332c55696DaA; 
        _setDefaultRoyalty(recipient, 1000);
        approvedRecipients[recipient] = true;
        approvedRecipientsList.push(recipient);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981, IERC165) returns (bool) {
        return interfaceId == type(ERC2981).interfaceId ||  interfaceId == type(IERC1155).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
    * @notice Reverts if the ID does not exist
    * @param id Token id
    */
    function idExists(uint256 id) internal view {
        require(idHash[id] != 0, "Provided ID does not exist");
    }


    /**
    * @notice Allows artManager to add new art piece to the contract
    * @param hashes Array of IPFS CIDs for metadata representing the art pieces
    * @return uint256[] Array of newly added ids
    */
    function newArt(bytes[] memory hashes) external onlyArtManager returns (uint256[] memory) {
        require(hashes.length > 0, "No new art to add");

        uint256[] memory result = new uint256[](hashes.length);
        for(uint256 i=0; i<hashes.length; i++) {
            uint256 _id = idCounter;
            bytes memory tmpHash = hashes[i];
            bytes32 tmp;

            assembly {
                tmp := mload(add(add(tmpHash, 2), 32))
            }

            idHash[_id] = tmp;
            mintEnabledId[_id] = true;
            result[i] = _id;
            idCounter++;

            emit NewArt(_id, tmpHash);
        }

        return result;
    }

    /**
    * @notice Mints given amount of specific art pieces to sender address
    * @param id Art piece ID
    * @param amount Amount of tokens to mint
    */
    function mint(uint256 id, uint256 amount, address[] memory to) external payable nonReentrant {
        require(mintEnabled, "Minting disabled");
        idExists(id);
        require(mintEnabledId[id], "Minting disabled for id");
        require(msg.value >= amount * minPrice, "Not enough ETH sent");
        uint256 _maxSupply = maxSupply[id];
        require(_maxSupply == 0 || _maxSupply > totalSupply[id], "Max supply reached");

        totalSupply[id] += amount;
        totalCollected += msg.value;
        _mint(msg.sender, id, amount, "");

        if (autoForward) {
            _forwardMulti(to, msg.value);
        }

        emit Contributed(msg.sender, msg.value);
    }

    /**
    * @notice Mints art pieces in batch
    * @param ids Array of art piece IDs to mint
    * @param amounts Array of amounts of tokens to mint
    */
    function mintBatch(
        uint256[] memory ids,
        uint256[] memory amounts,
        address[] memory to,
        bytes memory data
    ) external payable nonReentrant {
        require(mintEnabled, "Minting disabled");
        uint256 totalAmount;
        for(uint256 i=0; i<amounts.length; i++) {
            uint256 id = ids[i];
            totalAmount += amounts[i]; 
            idExists(id);
            uint256 _maxSupply = maxSupply[id];
            require(_maxSupply == 0 || _maxSupply > totalSupply[id], "Max supply reached");
            require(mintEnabledId[id], "Minting disabled for id");

            totalSupply[ids[i]] += amounts[i];
        }

        require(msg.value >= totalAmount * minPrice, "Not enough ETH sent");

        totalCollected += msg.value;

        _mintBatch(msg.sender, ids, amounts, data);

        if (autoForward) {
            _forwardMulti(to, msg.value);
        }

        emit Contributed(msg.sender, msg.value);
    }

    /**
    * @notice Public wrapper of _forward method
    * @param to recipient address (must be in approvedRecipients)
    * @param amount amount of ETH to send
    */
    function forward(address to, uint256 amount) public onlyOwner {
        _forward(to, amount);
    }

    /**
    * @notice Transfers given amount to a given address if the address is approved
    * @param to recipient address (must be in approvedRecipients)
    * @param amount amount of ETH to send
    */
    function _forward(address to, uint256 amount) internal {
        require(approvedRecipients[to], "Not a valid recipient");
        require(address(this).balance >= amount, "Not enough ETH");

        payable(to).transfer(amount);
        
        emit Forwarded(to, amount);
    }

    /**
    * @notice Forward given ETH value equally to multiple approved addresses
    * @param to List of recipients
    * @param amount amount of ETH to forward
    */
    function _forwardMulti(address[] memory to, uint256 amount) internal {
        uint256 toForward = amount / to.length;
        for(uint256 i=0; i<to.length; i++) {
            if(i == to.length - 1) {
                uint256 rest = amount - toForward*to.length;
                toForward += rest;
            }

            _forward(to[i], toForward);
        }
    } 

    /**
    * @notice Splits contract ETH balance among the list of addresses based on given portions
    * @param recipients Array of recipient addresses
    * @param portions Array of portions to transfer to recipients in percent (sum must be <= 100)
    */  
    function split(address[] memory recipients, uint256[] memory portions) external onlyOwner nonReentrant {
        require(recipients.length == portions.length, "Recipients and portions do not match");
        uint256 sum;
        for(uint256 i=0; i<portions.length; i++) {
            sum += portions[i];
        }
        require(sum <= 100, "Cannot distribute more than 100%");

        uint256 balance = address(this).balance;
        for(uint256 i=0; i<recipients.length; i++) {
            uint256 toSend = balance * portions[i] / 100;
            _forward(recipients[i], toSend);
        }
    }

    /**
    * @notice Sets an address is approved recipient
    * @param to Address to configure
    * @param enable Whether the address is approved
    */
    function setApprovedRecipient(address to, bool enable) external onlyOwner {
        require(approvedRecipients[to] != enable, "Already configured");
        require(to != address(0), "Cannot approve 0 address");

        approvedRecipients[to] = enable;
        if(enable) {
            approvedRecipientsList.push(to);
        } else {
            for(uint256 i=0; i<approvedRecipientsList.length; i++) {
                if(approvedRecipientsList[i] == to) {
                    approvedRecipientsList[i] = approvedRecipientsList[approvedRecipientsList.length-1];
                    approvedRecipientsList.pop();
                    break;
                }
            }
            
        }
    }

    /**
    * @notice Sets minimal price per token
    * @param amount Minimal price in wei (10**18)
    */
    function setMinPrice(uint256 amount) external onlyOwner {
        require(amount > 0, "Min price cannot be 0");

        uint256 oldPrice = minPrice;
        minPrice = amount;

        emit NewMinPrice(oldPrice, minPrice);
    }

    /**
    * @notice Sets the art manager
    * @param account Address to be used as art manager
    */
    function setArtManager(address account) external onlyOwner {
        require(account != address(0), "Address 0");

        artManager = account;
    }

    /**
    * @notice Enable/Disable minting for whole collection
    * @param enable Whether the minting is enable or not
    */
    function setMintEnabled(bool enable) external onlyOwner {
        mintEnabled = enable;

        emit MintingEnabled(enable);
    }

    /**
    * @notice Enable/Disable minting for given token id
    * @param id Token id
    * @param enable Whether the minting is enabled or not */
    function setMintEnabledForId(uint256 id, bool enable) external onlyArtManager {
        idExists(id);
        mintEnabledId[id] = enable;

        emit MintingEnabledId(id, enable);
    }

    /**
    * @notice Sets maximum supply for given token id
    * @param id Token id
    * @param max Maximum supply
    */
    function setMaxSupply(uint256 id, uint256 max) external onlyArtManager {
        idExists(id);
        maxSupply[id] = max;
    }

    /**
    * @notice Enable/Disable automatic forwarding of ETH to  */
    function setAutoForward(bool enable) external onlyOwner {
        require(autoForward != enable, "Already set");
        autoForward = enable;
    }

    /**
    * @notice Allows rescuing ERC20 tokens from the contract
    * @param token Token address
    * @param to Recipient address
    */
    function rescueTokens(address token, address to) external onlyOwner nonReentrant {
        require(token != address(0), "Nothing to rescue");

        uint256 amount = IERC20(token).balanceOf(address(this));

        if (amount > 0) {
            require(IERC20(token).transfer(to, amount), "Transfer failed");
        }

        emit Rescued(token, amount, to);
    }

    /**
    * @notice Generates full IPFS CID from stored bytes32 part
    * @param id Token id
    */
    function getHash(uint256 id) public view returns (bytes memory) {
        bytes32 hash = idHash[id];
        require(hash != 0, "Incorrect ID");
        uint8 x = 0x12;
        uint8 y = 0x20;
        return abi.encodePacked(x, y, hash);
    }

    /**
    * @notice Constructs and returns URI to token metadata on IPFS
    * @param id Token id
    * @return string URI to metadata.json*/
    function uri(uint256 id) public view override returns(string memory) {
        bytes memory hash = getHash(id);
        return string(abi.encodePacked(_uri, Base58.toBase58(hash), "/metadata.json"));
    }


    struct TokenInfo {
        string uri;
        bool mintable;
        uint256 maxSupply;
        uint256 totalSupply;
    }

    /**
    * @notice Get URIs for all tokens
    * returns string[] Array of URIs */
    function getInfo() external view returns(TokenInfo[] memory) {
        TokenInfo[] memory info = new TokenInfo[](idCounter);

        for(uint256 i=0; i<idCounter; i++) {
            info[i].maxSupply = maxSupply[i]; 
            info[i].uri = uri(i);
            info[i].totalSupply = totalSupply[i];
            info[i].mintable = mintEnabledId[i];
        }

        return info;
    }

    function getApprovedRecipients() external view returns(address[] memory) {
        return approvedRecipientsList;
    }

    function contractURI() public view returns (string memory) {
        return _contractMetadataURI;
    }

    modifier onlyArtManager() {
        require(msg.sender == artManager, "Not  the art manager");
        _;
    }
}
