// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

/*
   _      ΞΞΞΞ      _
  /_;-.__ / _\  _.-;_\
     `-._`'`_/'`.-'
         `\   /`
          |  /
         /-.(
         \_._\
          \ \`;
           > |/
          / //
          |//
          \(\
           ``
     defijesus.eth
*/

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

error AlreadyClaimed();
error NotTheOwner();
error TooMany();
error NotJesus();

contract Wiiilady is ERC721 {

    uint256 public foolishnessPerc;

    string public MILADY_JPEG_URI = "https://www.miladymaker.net/milady/";

    address public JESUS;

    address public foolishnessAccumulator;

    ERC721 public constant MILADYS =
        ERC721(0x5Af0D9827E0c53E4799BB226655A1de152A425a5);

    mapping(uint256 => bool) public hasClaimed;
    mapping(uint256 => uint256) public wiiidooor;

    // 1 Milady = 1 Wiiilady
    function claimWiiilady(uint256 tokenId) public payable {
        if (hasClaimed[tokenId]) revert AlreadyClaimed();
        if (MILADYS.ownerOf(tokenId) != msg.sender) revert NotTheOwner();
        hasClaimed[tokenId] = true;
        _mint(msg.sender, tokenId);
    }

    // 10 Milady = 10 Wiiilady
    function claimMultipleWiiiladys(uint256[] calldata tokenIds) public payable {
        if (tokenIds.length > 40) revert TooMany();
        unchecked {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                if (hasClaimed[tokenIds[i]]) revert AlreadyClaimed();
                if (MILADYS.ownerOf(tokenIds[i]) != msg.sender) revert NotTheOwner();
                hasClaimed[tokenIds[i]] = true;
                _mint(msg.sender, tokenIds[i]);
            }
        }
    }

    // you need to approve this contract to move your Milady before smoking crack
    // milady is crack, this is the pipe, the miners are the smoke
    function smokeCrack(uint256 tokenId) public payable {
        if (MILADYS.ownerOf(tokenId) != msg.sender) revert NotTheOwner();
        wiiidooor[tokenId] += 100;
        MILADYS.transferFrom(msg.sender, block.coinbase, tokenId);
    }

    // you can groom miladys that are not yours to make the wiiider
    // send a tip bigger than 0.001Ξ to the miner or else you will go to jail
    function groom(uint256 tokenId) public payable {
        require(this.ownerOf(tokenId) != msg.sender);
        require(msg.value > 0.001 ether);
        (bool success, ) = block.coinbase.call{value:msg.value}("");
        require(success);
        unchecked {
            wiiidooor[tokenId] += 1;
        }
    }

    function getWidooorMultiplier(uint256 tokenId) public view returns (uint256 mult) {
        mult = wiiidooor[tokenId];
        unchecked {
            if (mult == 0) {
                mult = 2;
            } else {
                mult += 2;
            } 
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        uint256 mult = getWidooorMultiplier(tokenId);
        uint256 w = 1000 * mult;
        string[8] memory parts;
        parts[0] = '<svg width="';
        parts[1] = toString(w);
        parts[2] = '" height="1250" xmlns="http://www.w3.org/2000/svg"> <image href="';
        parts[3] = MILADY_JPEG_URI;
        parts[4] = toString(tokenId);
        parts[5] = '.png" transform="scale(';
        parts[6] = toString(mult);
        parts[7] = ',1)" /> </svg>';
        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7]
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Wiiilady #',
                        toString(tokenId),
                        '","attributes": [{"trait_type": "wiiideness","value":',
                        toString(mult),
                        '}],"description": "widemiladyhappy", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        super.transferFrom(from, to, id);
        wiiidooor[id] += 1;
    }

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        if (foolishnessAccumulator != address(0)) {
            receiver = foolishnessAccumulator;
        } else {
            receiver = block.coinbase;
        }

        royaltyAmount = (_salePrice * foolishnessPerc) / 10000;
        return (receiver, royaltyAmount);
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    constructor() ERC721("Wiiilady", "WLD") {
        JESUS = msg.sender;
        foolishnessPerc = 1000;
    }

    function setURI(string memory uri) external payable {
        if (msg.sender != JESUS) revert NotJesus();
        MILADY_JPEG_URI = uri;
    }

    function setFoolishnessAcumulator(address _acc) external payable {
        if (msg.sender != JESUS) revert NotJesus();
        foolishnessAccumulator = _acc;
    }

    function setFoolishnessPerc(uint256 perc) external payable {
        if (msg.sender != JESUS) revert NotJesus();
        foolishnessPerc = perc;
    }

    function reincarnate(address _jesus) external payable {
        if (msg.sender != JESUS) revert NotJesus();
        require(_jesus != address(0));
        JESUS = _jesus;
    }

    function die() external payable {
        if (msg.sender != JESUS) revert NotJesus();
        JESUS = address(0);
    }
}

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
