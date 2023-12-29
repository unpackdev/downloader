//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./base64.sol";

interface IRenderer {
    function render(uint256 seed) external view returns (string calldata);
}

contract TheQuest is ERC721, ERC721Enumerable, Ownable {
    uint256 public supply;
    bool public isOpen;
    IRenderer public renderer;

    mapping(uint256 => uint8) public team;

    constructor() ERC721("The Quest", "QUEST") {
        isOpen = false;
    }

    function setRender(address _contract) external onlyOwner {
        renderer = IRenderer(_contract);
    }

    // half goes to the team, the other half will be used for airdrops to the community.
    function communityMint(uint256 qty, uint8 _team) public onlyOwner {
        require(supply <= 4269, "!max reached");

        for (uint256 i = 0; i < qty; i++) {
            _mint(msg.sender, supply);
            team[supply] = _team;

            supply = supply + 1;
        }
    }

    // qty to mint and team 0 or 1 you want to belong to.
    function mint(uint256 qty, uint8 _team) public {
        require(tx.origin == msg.sender, "!contract");
        require(_team == 0 || _team == 1, "!!!");
        require(isOpen || owner() == msg.sender, "!start");
        require(qty <= 3, "!count limit");
        require(supply <= 4000, "!max reached");

        for (uint256 i = 0; i < qty; i++) {
            _mint(msg.sender, supply);

            team[supply] = _team;

            supply = supply + 1;
        }
    }

    function open() public onlyOwner {
        isOpen = true;
    }

    function getTeam(uint256 _tokenID) public view returns (string memory) {
        uint8 _team = team[_tokenID];
        if (_team == 0) {
            return "Sword";
        } else {
            return "Shield";
        }
    }

    function getScore(uint256 _tokenID) public pure returns (uint256) {
        uint256 score = uint256(keccak256(abi.encodePacked(_tokenID))) % 100;
        return score;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory image = (renderer.render(_tokenId));
        string memory attributes = string(
            abi.encodePacked(
                '", "attributes":[{ "trait_type": "Team","value":"',
                getTeam(_tokenId),
                '"}]}'
            )
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    (
                        Base64.encode(
                            bytes(
                                (
                                    abi.encodePacked(
                                        '{"name":"The Quest #',
                                        uint2str(_tokenId),
                                        '","image": ',
                                        '"',
                                        "data:image/svg+xml;base64,",
                                        Base64.encode(bytes(image)),
                                        attributes
                                    )
                                )
                            )
                        )
                    )
                )
            );
    }

    receive() external payable {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721)
        returns (bool)
    {
        return ERC721Enumerable.supportsInterface(interfaceId);
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
