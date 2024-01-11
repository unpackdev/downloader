pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC20Burnable.sol";

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

contract ClubOfGoatsToken is ERC20Burnable, Ownable {
    constructor(address _team) public ERC20("Loser G.O.A.T.S Token", "GOAT") {
        _mint(msg.sender, 11000000 * 10**decimals());
        transfer(_team, (totalSupply() * 4) / 10);
    }

    function mint(address _address, uint256 _amount) external onlyOwner {
        transfer(_address, _amount);
    }
}

contract ClubOfGoatsPFP is ERC721Enumerable, Ownable, ReentrancyGuard {
    uint256 public maxSupply;
    string public baseURI;
    uint256 public maxBatch;
    string public defaultURI;
    bytes32 public whitelistRoot;

    event Log(address);

    uint256 public publicPrice;

    uint256 public whitelistPrice;

    uint256 public publicStartTime;

    uint256 public publicEndTime;

    uint256 public whitelistStartTime;

    uint256 public whitelistEndTime;

    uint256 public publicNum;

    uint256 public whitelistNum;

    uint256 public maxPublicNum;

    uint256 public maxWhitelistNum;

    uint256 public reservedNum;

    uint256 public maxReservedNum;

    ClubOfGoatsToken public token;

    address public seaport;

    uint256 public mintTokenAmount;

    using Strings for uint256;

    constructor(
        string memory _baseURI,
        string memory _defaultURI,
        bytes32 _whitelistRoot
    ) public ERC721("Loser G.O.A.T.S", "Loser G.O.A.T.S") {
        token = new ClubOfGoatsToken(msg.sender);
        uint256 _maxBatch = 1;
        uint256 _maxSupply = 1100;
        maxReservedNum = 330;
        maxWhitelistNum = 800;
        maxPublicNum = 1100;
        whitelistStartTime = 1655902800;
        whitelistEndTime = 1655906400;
        whitelistPrice = 0 ether;
        publicStartTime = 1655906400;
        publicEndTime = 9655902800;
        publicPrice = 0 ether;
        setBaseURI(_baseURI);
        setMaxBatch(_maxBatch);
        maxSupply = _maxSupply;
        defaultURI = _defaultURI;
        whitelistRoot = _whitelistRoot;
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
        mintToken(to);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
        mintToken(to);
    }

    function mintToken(address _to) internal {
        emit Log(msg.sender);
        if (seaport == msg.sender && seaport != address(0)) {
            token.mint(_to, mintTokenAmount);
        }
    }

    function setMintTokenConfig(address _seaport, uint256 _mintTokenAmount)
        external
        onlyOwner
    {
        seaport = _seaport;
        mintTokenAmount = _mintTokenAmount;
    }

    function setPrice(uint256 _publicPrice, uint256 _whitelistPrice)
        external
        onlyOwner
    {
        publicPrice = _publicPrice;
        whitelistPrice = _whitelistPrice;
    }

    function setMintTime(
        uint256 _publicStartTime,
        uint256 _publicEndTime,
        uint256 _whitelistStartTime,
        uint256 _whitelistEndTime
    ) external onlyOwner {
        publicStartTime = _publicStartTime;
        publicEndTime = _publicEndTime;
        whitelistStartTime = _whitelistStartTime;
        whitelistEndTime = _whitelistEndTime;
    }

    function setMaxNum(
        uint256 _maxPublicNum,
        uint256 _maxWhitelistNum,
        uint256 _maxReservedNum
    ) external onlyOwner {
        maxPublicNum = _maxPublicNum;
        maxWhitelistNum = _maxWhitelistNum;
        maxReservedNum = _maxReservedNum;
    }

    function mint(address _addresss, uint256 _num) internal nonReentrant {
        require(
            _num <= maxBatch && _num > 0,
            "Num must greater 0 and lower maxBatch"
        );
        require(totalSupply() + _num <= maxSupply, "Num must lower maxSupply");
        for (uint256 i = 0; i < _num; i++) {
            _safeMint(_addresss, totalSupply() + 1);
        }
    }

    function mintReservedBatch(address _address, uint256 _num)
        external
        onlyOwner
    {
        require(
            reservedNum + _num <= maxReservedNum,
            "reservedNum must lower maxReservedNum"
        );
        mint(_address, _num);
        reservedNum += _num;
    }

    function mintReserved(address[] calldata _address) external onlyOwner {
        uint256 num = _address.length;
        require(
            reservedNum + num <= maxReservedNum,
            "reservedNum must lower maxReservedNum"
        );
        for (uint256 i = 0; i < num; i++) {
            mint(_address[i], 1);
        }
        reservedNum += num;
    }

    function whitelistMint(uint256 _num, bytes32[] memory _proof)
        external
        payable
    {
        require(_num <= 1, "Num must lt or eq 1");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_proof, whitelistRoot, leaf),
            "Verification failed"
        );
        require(
            msg.value == whitelistPrice * _num,
            "Value must eq whitelistPrice*num"
        );
        require(
            whitelistStartTime <= block.timestamp,
            "WhitelistMint has not started yet"
        );
        require(whitelistEndTime > block.timestamp, "WhitelistMint has ended");
        require(
            whitelistNum + _num <= maxWhitelistNum,
            "Num must lower maxWhitelistNum"
        );
        mint(msg.sender, _num);
        whitelistNum += _num;
    }

    function publicMint(uint256 _num) external payable {
        require(
            msg.value == publicPrice * _num,
            "Value must eq publicPrice*num"
        );
        require(
            publicStartTime <= block.timestamp,
            "PublicMint has not started yet"
        );
        require(publicEndTime > block.timestamp, "PublicMint has ended");
        require(
            publicNum + _num <= maxPublicNum,
            "Num must lower maxPublicNum"
        );
        mint(msg.sender, _num);
        publicNum += _num;
    }

    function setRoot(bytes32 _whitelistRoot) external onlyOwner {
        whitelistRoot = _whitelistRoot;
    }

    function setMaxBatch(uint256 _maxBatch) public onlyOwner {
        maxBatch = _maxBatch;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setDefaultURI(string memory _defaultURI) public onlyOwner {
        defaultURI = _defaultURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory imageURI = bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"))
            : defaultURI;

        return imageURI;
    }
}
