// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";

interface IFeeDistributor {
    function ve_for_at(address _user, uint256 _timestamp)
        external
        returns (uint256);
}

contract PickleBirthday is ERC721Enumerable, Ownable {
    string public _tokenURI;
    uint256 public snapshotTime = 1629746531;
    mapping(address => bool) public userClaimed;

    IFeeDistributor public constant DILL = IFeeDistributor(
        0x74C6CadE3eF61d64dcc9b97490d9FbB231e4BdCc
    );

    constructor(string memory _uri)
        public
        ERC721("Pickle Finance Birthday NFT", "PBDAY")
    {
        _tokenURI = _uri;
    }

    // Reserver 20 mints for the team to distribute
    function reserveMints() public onlyOwner {
        uint256 supply = totalSupply();
        uint256 i;
        for (i = 0; i < 20; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        override
        view
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory uri = _baseURI();
        return uri;
    }

    function _baseURI() internal override view returns (string memory) {
        return _tokenURI;
    }

    function mintNFT(address recipient) public returns (uint256) {
        require(!userClaimed[msg.sender], "User has already claimed NFT");

        // Require a DILL balance > 10 at the snapshotTime
        require(
            DILL.ve_for_at(msg.sender, snapshotTime) >= mul(10, 1e18),
            "User balance does not qualify"
        );

        uint256 supply = totalSupply();
        uint256 newItemId = supply;
        _mint(recipient, newItemId);

        userClaimed[msg.sender] = true;

        return newItemId;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }
}
