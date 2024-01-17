// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./SafeMath.sol";
import "./ERC1155.sol";
import "./Ownable.sol";

import "./HasContractURI.sol";
import "./HasTokenURI.sol";
import "./HasSecondarySaleFees.sol";

contract ERC1155Base is HasSecondarySaleFees, Ownable, HasTokenURI, HasContractURI, ERC1155 {

    using SafeMath for uint256;

    struct Fee {
        address payable recipient;
        uint256 value;
    }

    // id => creator
    mapping (uint256 => address) public creators;
    // id => fees
    mapping (uint256 => Fee[]) public fees;

    /*
     * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *
     * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
     */
    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

    /*
     * bytes4(keccak256('contractURI()')) == 0xe8a3d485
     */
    bytes4 private constant _INTERFACE_ID_CONTRACT_URI = 0xe8a3d485;

    constructor(string memory URI, string memory tokenURIPrefix) ERC1155("") HasContractURI(contractURI) HasTokenURI(tokenURIPrefix) {

    }

    function uri(uint256 _id) public view virtual override returns (string memory) {
      return _tokenURI(_id);
    }


    function getFeeRecipients(uint256 id) public view override returns (address payable[] memory) {
        Fee[] memory _fees = fees[id];
        address payable[] memory result = new address payable[](_fees.length);
        for (uint i = 0; i < _fees.length; i++) {
            result[i] = _fees[i].recipient;
        }
        return result;
    }

    function getFeeBps(uint256 id) public view override returns (uint[] memory) {
        Fee[] memory _fees = fees[id];
        uint[] memory result = new uint[](_fees.length);
        for (uint i = 0; i < _fees.length; i++) {
            result[i] = _fees[i].value;
        }
        return result;
    }

    // Creates a new token type and assings _initialSupply to minter
    function _mint(address to, uint256 _id, Fee[] memory _fees, uint256 _supply, string memory _uri) internal {
        require(creators[_id] == address(0x0), "Token is already minted");
        require(_supply != 0, "Supply  be positive");
        require(bytes(_uri).length > 0, "uri  be set");

        creators[_id] = to;
        address[] memory recipients = new address[](_fees.length);
        uint[] memory bps = new uint[](_fees.length);
        for (uint i = 0; i < _fees.length; i++) {
            require(_fees[i].recipient != address(0x0), "Recipient  be present");
            require(_fees[i].value != 0, "Fee value  be positive");
            fees[_id].push(_fees[i]);
            recipients[i] = _fees[i].recipient;
            bps[i] = _fees[i].value;
        }
        if (_fees.length > 0) {
            emit SecondarySaleFees(_id, recipients, bps);
        }
        super._mint(to, _id, _supply, "");
        // _balances[_id][to] = _supply;
        _setTokenURI(_id, _uri);

        // Transfer event with mint semantic
        emit URI(_uri, _id);
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _INTERFACE_ID_FEES == interfaceId ||
            _INTERFACE_ID_CONTRACT_URI == interfaceId ||
            super.supportsInterface(interfaceId);
    }



    function burn(address _owner, uint256 _id, uint256 _value) external {

        require(_owner == msg.sender || isApprovedForAll(_owner, msg.sender) == true, "Need operator approval for 3rd party burns.");

        _burn(_owner, _id, _value);
    }

    function setTokenURIPrefix(string memory tokenURIPrefix) public onlyOwner {
        _setTokenURIPrefix(tokenURIPrefix);
    }

    function setContractURI(string memory contractURI) public onlyOwner {
        _setContractURI(contractURI);
    }
}
