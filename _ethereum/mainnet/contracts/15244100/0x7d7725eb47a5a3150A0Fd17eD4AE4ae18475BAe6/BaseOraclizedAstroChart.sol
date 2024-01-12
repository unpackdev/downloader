// contracts/AstroChart.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ChainlinkClient.sol";
import "./OracleUtils.sol";
import "./SVGGenerator.sol";
import "./AstroChartLib.sol";

abstract contract BaseOraclizedAstroChart is ERC721Enumerable, Ownable, ChainlinkClient {
    using Chainlink for Chainlink.Request;

    /***
     * ChainLink Block start
     */
    address internal oracle;

    bytes32 internal jobId;

    uint256 internal fee;

    string internal oracleRequestHost;

    SVGGenerator internal svgGenerator;

    mapping(bytes32 => AstroChartResponse) internal request2Response;

    struct AstroChartResponse {
        uint16[] cusps;
        uint16[] planets;
        bool exists;
    }

    /**
     * ChainLink Block end
     */

    // record tokenId to oracle request id
    mapping(uint256 => bytes32) public tokenId2OracleRequestId;

    /**
     Chainlink Relative Block start!!!!
     */
    function getLinkTokenAddress() external view returns (address) {
        return chainlinkTokenAddress();
    }

    /**
    Use to withdraw remain link from contract
     */
    function withdrawLink() external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 1000000000000000000 (to remove decimal places from data).
     */
    function sendRequestToOracle(
        uint256 tokenId,
        uint16[] memory monthAndDay,
        string memory remaining
    ) internal returns (bytes32) {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        string memory url = OracleUtils.genRequestURL(oracleRequestHost, monthAndDay, remaining);

        // Set the URL to perform the GET request on
        request.add("get", url);
        request.add("path_cusps", "cusps");
        request.add("path_planets", "planets");

        // Sends the request
        bytes32 requestId = sendChainlinkRequestTo(oracle, request, fee);

        tokenId2OracleRequestId[tokenId] = requestId;

        return requestId;
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfill(
        bytes32 _requestId,
        uint16[] calldata _cusps,
        uint16[] calldata _planets
    ) external recordChainlinkFulfillment(_requestId) {
        request2Response[_requestId] = AstroChartResponse({cusps: _cusps, planets: _planets, exists: true});
    }

    /**
    Chainlink Relative Block end!!!
     */

    function tokenURIOf(uint256 tokenId, uint256 gen0RootTokenId) internal view returns (string memory) {
        bytes32 requestId = tokenId2OracleRequestId[tokenId];
        require(requestId != "0x0", "Token not minted");

        AstroChartResponse memory response = request2Response[requestId];

        if (!response.exists) {
            return svgGenerator.nonExistSVGInOpenSeaFormat(tokenId, gen0RootTokenId);
        } else {
            AstroChartArgs memory args = AstroChartLib.getAstroArgsOf(tokenId);
            return
                svgGenerator.genSVGInOpenSeaFormat(
                    response.cusps,
                    response.planets,
                    args.generation,
                    tokenId,
                    args.monthAndDay[0],
                    args.monthAndDay[1],
                    gen0RootTokenId
                );
        }
    }

    function getResponseOf(uint256 tokenId) public view returns (AstroChartResponse memory) {
        bytes32 requestId = tokenId2OracleRequestId[tokenId];
        return request2Response[requestId];
    }

    function getOracleGasFee() public view returns (uint256) {
        return AstroChartLib.getOracleGasFee();
    }
}
