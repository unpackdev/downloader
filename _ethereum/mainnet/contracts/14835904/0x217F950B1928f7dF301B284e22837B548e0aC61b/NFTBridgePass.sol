// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Base64.sol";
import "./ERC721.sol";
import "./Strings.sol";

/**
 * @title IL1ERC20Bridge
 */
interface IL1ERC20Bridge {
    /**
     * @dev Deposit an amount of ETH to a recipient's balance on L2.
     * @param _to L2 address to credit the withdrawal to.
     * @param _l2Gas Gas limit required to complete the deposit on L2.
     * @param _data Optional data to forward to L2. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function depositETHTo(
        address _to,
        uint32 _l2Gas,
        bytes calldata _data
    ) external payable;
}

interface INFTBridgePass {
    function l2TokenBridge() external view returns (address);

    function l2Gas() external view returns (uint32);
}

contract NFTBridgePass is INFTBridgePass, ERC721 {
    address public immutable override l2TokenBridge;

    uint32 public immutable override l2Gas;

    uint256 public immutable price;

    uint256 public immutable limit;

    string public baseURI;

    string public description;

    string public imageURI;

    uint256 public totalSupply = 0;

    constructor(
        address _l2TokenBridge,
        uint32 _l2Gas,
        uint256 _price,
        uint256 _limit,
        string memory _baseURI,
        string memory _description,
        string memory _imageURI
    ) ERC721("Mirror L2 Launch Invite", "MIRRORBRIDGEPASS") {
        l2TokenBridge = _l2TokenBridge;
        l2Gas = _l2Gas;
        price = _price;
        limit = _limit;
        baseURI = _baseURI;
        description = _description;
        imageURI = _imageURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "',
                                    name(),
                                    abi.encodePacked(
                                        " ",
                                        Strings.toString(tokenId),
                                        "/",
                                        Strings.toString(limit)
                                    ),
                                    '", "description": "',
                                    description,
                                    '", "animation_url": "',
                                    _constructURI(tokenId, ownerOf(tokenId)),
                                    '", "image": "',
                                    imageURI,
                                    '", "attributes":[{ "trait_type": "Serial", "value": ',
                                    Strings.toString(tokenId),
                                    "}] }"
                                )
                            )
                        )
                    )
                )
            );
    }

    function contractURI() public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "',
                                    name(),
                                    '", "description": "',
                                    description,
                                    '", "image": "',
                                    imageURI,
                                    '", "external_link": "https://mirror.xyz" }'
                                )
                            )
                        )
                    )
                )
            );
    }

    function mint() external payable returns (uint256 tokenId) {
        require(msg.value == price, "invalid value");
        require(totalSupply < limit, "sold out");

        tokenId = ++totalSupply;

        _mint(msg.sender, tokenId);

        if (l2TokenBridge != address(0)) {
            IL1ERC20Bridge(l2TokenBridge).depositETHTo{value: msg.value}(
                msg.sender,
                l2Gas,
                ""
            );
        } else {
            // Send Ether back
            _sendEther(payable(msg.sender), msg.value);
        }
    }

    function _sendEther(address payable recipient, uint256 amount) internal {
        // Ensure sufficient balance.
        require(address(this).balance >= amount, "insufficient balance");

        // Send the value.
        // slither-disable-next-line low-level-calls
        (bool success, ) = recipient.call{value: amount, gas: gasleft()}("");

        require(success, "recipient reverted");
    }

    function _constructURI(uint256 tokenId, address owner)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    baseURI,
                    "?totalTickets=",
                    Strings.toString(limit),
                    "&ticketNumber=",
                    Strings.toString(tokenId),
                    "&ownerAddress=",
                    _addressToString(owner)
                )
            );
    }

    // https://ethereum.stackexchange.com/questions/8346/convert-address-to-string/8447#8447
    function _addressToString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = _char(hi);
            s[2 * i + 1] = _char(lo);
        }
        return string(abi.encodePacked("0x", s));
    }

    function _char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
