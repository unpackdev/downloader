// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC721.sol";
import "./ERC165.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Strings.sol";
import "./Context.sol";

interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721 is Context {
    using Strings for uint256;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
            interfaceId == 0x2a55205a; //For Royalty
    }

    string public name;

    string public symbol;

    mapping(address => uint256) internal _balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(uint256 => uint256) public tokenType;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        require(_exists(tokenId), "No token with this Id exists");

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf[tokenId];
        return owner != address(0);
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function balanceOf(address _acc) public view returns (uint256) {
        return _balanceOf[_acc];
    }

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender],
            "Not authorized"
        );

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
        require(from == ownerOf[id], "WRONG FROM");

        require(to != address(0), "WRONG TO");

        require(
            msg.sender == from ||
                isApprovedForAll[from][msg.sender] ||
                msg.sender == getApproved[id],
            "NOT AUTHORIZED"
        );

        unchecked {
            _balanceOf[from]--;
            _balanceOf[to]++;
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
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    ""
                ) ==
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
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _mint(
        address to,
        uint256 id,
        uint8 tknType
    ) internal virtual {
        require(to != address(0), "INVALID_TO");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        unchecked {
            _balanceOf[to]++;
        }

        ownerOf[id] = to;
        tokenType[id] = tknType;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];
        require(msg.sender == owner, "NOT_PERMITED");
        require(owner != address(0), "NOT_MINTED");

        delete ownerOf[id];
        delete getApproved[id];

        emit Transfer(msg.sender, address(0), id);
    }

    // function _safeMint(address to, uint256 id) internal virtual {
    //     _mint(to, id);

    //     require(
    //         to.code.length == 0 ||
    //             ERC721TokenReceiver(to).onERC721Received(
    //                 msg.sender,
    //                 address(0),
    //                 id,
    //                 ""
    //             ) ==
    //             ERC721TokenReceiver.onERC721Received.selector,
    //         "UNSAFE_RECIPIENT"
    //     );
    // }

    // function _safeMint(
    //     address to,
    //     uint256 id,
    //     bytes memory data
    // ) internal virtual {
    //     _mint(to, id);

    //     require(
    //         to.code.length == 0 ||
    //             ERC721TokenReceiver(to).onERC721Received(
    //                 msg.sender,
    //                 address(0),
    //                 id,
    //                 data
    //             ) ==
    //             ERC721TokenReceiver.onERC721Received.selector,
    //         "UNSAFE_RECIPIENT"
    //     );
    // }
}
