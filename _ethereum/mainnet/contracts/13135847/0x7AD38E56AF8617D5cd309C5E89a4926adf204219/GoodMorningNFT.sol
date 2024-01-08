pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Counters.sol";
import "./base64.sol";
import "./HexStrings.sol";

contract GoodMorningNFT is ERC721 {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    using HexStrings for uint160;

    event GoodMorning(address _minter, uint256 _tokenId, address _recipient);

    uint public limit;
    uint256 public price;
    address public beneficiary;

    mapping(uint256 => string) public names;
    mapping(uint256 => string) public colors;
    string [8] public colorChoices = ["F46D67", "EB6859", "FC8862", "FDA26B", "FDBB63", "F9A44C", "F58C34", "F58C34"];

    constructor(uint _limit, uint256 _price, address _beneficiary) ERC721("GoodMorning", "GM") {
        limit = _limit;
        price = _price;
        beneficiary = _beneficiary;
    }

    function mint(string memory text, address recipient) public payable returns (uint256) {

        require(msg.value >= price, "price too low");

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        require(newItemId <= limit, "at limit");

        _safeMint(recipient, newItemId);

        names[newItemId] = text;
        // super-secret method of color calculation. totally unpredictable.
        colors[newItemId] = colorChoices[uint(blockhash(block.number - 1)) % colorChoices.length];

        emit GoodMorning(msg.sender, newItemId, recipient);

        return newItemId;
    }

    function withdrawFunds() public {
        require(msg.sender == beneficiary, 'only beneficiary');
        uint amount = address(this).balance;

        (bool success,) = beneficiary.call{value : amount}("");
        require(success, "Failed");
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function tokenURI(uint256 id) public view override returns (string memory) {

        require(_exists(id), "not exist");

        string memory name = string(abi.encodePacked("gm ", names[id]));
        string memory image = Base64.encode(bytes(abi.encodePacked(
                '<svg width="350" height="350" xmlns="http://www.w3.org/2000/svg"><g><rect fill="#',
                colors[id],
                '" stroke="#000" x="0" y="0" width="350" height="350" id="svg_1" stroke-width="0"/>',
                '<text transform="matrix(1 0 0 1 0 0)" fill="#000000" stroke="#000" stroke-width="0" x="50%" y="50%" font-size="24" font-family="\'Courier New\'" text-anchor="middle" xml:space="preserve" font-weight="normal" font-style="normal">gm ',
                names[id],
                '</text></g></svg>'
            )));

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            name,
                            '", "external_url":"TODO',
                            '", "attributes": [{"trait_type": "Recipient", "value": "',
                            names[id],
                            '"}], "owner":"',
                            (uint160(ownerOf(id))).toHexString(20),
                            '", "image": "',
                            'data:image/svg+xml;base64,',
                            image,
                            '"}'
                        )
                    )
                )
            )
        );
    }

}