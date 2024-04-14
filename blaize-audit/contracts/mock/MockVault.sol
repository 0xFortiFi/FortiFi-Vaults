// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.21;

contract MockVault {
    bool public response = true;

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return response;
    }

    function setResponse(bool _response) public {
        response = _response;
    }
}
