//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "./ERC721.sol";
import "./IERC20.sol";
import "./Verifier.sol";

contract SolNSop is ERC721 {
    Verifier public claimVerifier;
    string public vows;

    address private _deployer;
    string[] private _metadata; // stored metadata
    mapping(uint256 => uint256) private _pMetadata; // metadata pointer

    event Congrats(string message);

    constructor(
        address claimVerifier_,
        string memory vows_,
        string[] memory metadata_
    ) ERC721("Sol&Sop Wedding NFT", "SOLNSOP") {
        claimVerifier = Verifier(claimVerifier_);
        _deployer = msg.sender;
        vows = vows_;
        _metadata = metadata_;
    }

    receive() external payable {
        if (msg.value > 0) {
            payable(_deployer).transfer(msg.value);
        }
    }

    function mint(
        uint256 tokenId,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256 metadataId,
        string memory message
    ) public payable {
        uint256[2] memory inputs;
        inputs[0] = tokenId;
        inputs[1] = uint256(uint160(msg.sender));
        require(
            claimVerifier.verifyProof(a, b, c, inputs),
            "SNARK proof failed"
        );
        emit Congrats(message);
        _pMetadata[tokenId] = metadataId;
        _mint(msg.sender, tokenId);
        if (msg.value > 0) {
            payable(_deployer).transfer(msg.value);
        }
    }

    function rescueERC20(address erc20) public {
        IERC20(erc20).transfer(
            _deployer,
            IERC20(erc20).balanceOf(address(this))
        );
    }

    function isClaimed(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked("ipfs://", _metadata[_pMetadata[tokenId]]));
    }
}
