import XCTest
@testable import tart

@available(macOS 14, *)
final class ControlSocketTests: XCTestCase {
  func testInitializerCreatesControlSocketBeforeReturning() async throws {
    let temporaryDirectory = try makeTemporaryDirectory()
    let originalDirectory = FileManager.default.currentDirectoryPath
    defer {
      FileManager.default.changeCurrentDirectoryPath(originalDirectory)
      try? FileManager.default.removeItem(at: temporaryDirectory)
    }

    let socketURL = URL(fileURLWithPath: "control.sock", relativeTo: temporaryDirectory)
    var controlSocket: ControlSocket? = try await ControlSocket(socketURL)
    let eventLoopGroup = try XCTUnwrap(controlSocket?.eventLoopGroup)

    do {
      let serverChannel = try XCTUnwrap(controlSocket?.serverChannel)
      XCTAssertTrue(FileManager.default.fileExists(atPath: socketURL.path))

      try await serverChannel.executeThenClose { _ in }
    }

    controlSocket = nil
    try await eventLoopGroup.shutdownGracefully()
  }

  func testInitializerPropagatesControlSocketCreationFailure() async throws {
    let temporaryDirectory = try makeTemporaryDirectory()
    let originalDirectory = FileManager.default.currentDirectoryPath
    defer {
      FileManager.default.changeCurrentDirectoryPath(originalDirectory)
      try? FileManager.default.removeItem(at: temporaryDirectory)
    }

    let socketURL = URL(fileURLWithPath: "missing/control.sock", relativeTo: temporaryDirectory)

    do {
      _ = try await ControlSocket(socketURL)
      XCTFail("Binding should fail when the socket's parent directory does not exist")
    } catch {
      XCTAssertFalse(FileManager.default.fileExists(atPath: socketURL.path))
    }
  }

  private func makeTemporaryDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
      UUID().uuidString,
      isDirectory: true
    )
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
    return directory
  }
}
