// frontend/test/features/chat/presentation/providers/chat_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:guide_scolaire/features/chat/domain/entities/message.dart';
import 'package:guide_scolaire/features/chat/repositories/i_chat_repository.dart';
import 'package:guide_scolaire/features/chat/presentation/providers/chat_provider.dart';
import 'package:guide_scolaire/features/auth/providers/auth_provider.dart';

// Mock généré avec mockito
class MockChatRepository extends Mock implements IChatRepository {}

class MockAuthProvider extends Mock implements AuthProvider {}

void main() {
  late ChatProvider provider;
  late MockChatRepository mockRepository;
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockRepository = MockChatRepository();
    mockAuthProvider = MockAuthProvider();
    when(mockAuthProvider.userId).thenReturn(1);
    provider = ChatProvider(
      chatRepository: mockRepository,
      authProvider: mockAuthProvider,
    );
  });

  test('sendMessage should add user message and repository response', () async {
    // Arrange
    const question = 'Qu\'est-ce qu\'une fraction ?';
    final responseMessage = Message(
      id: '123',
      content: 'Une fraction est une division...',
      isUser: false,
      timestamp: DateTime.now(),
    );
    when(mockRepository.sendMessage(question, userId: 1))
        .thenAnswer((_) async => responseMessage);

    // Act
    await provider.sendMessage(question);

    // Assert
    expect(provider.messages.length, 3); // welcome + user + assistant
    expect(provider.messages[1].content, question);
    expect(provider.messages[2].content, responseMessage.content);
    expect(provider.isLoading, false);
  });

  test('sendMessage should handle error gracefully', () async {
    // Arrange
    const question = 'Qu\'est-ce qu\'une fraction ?';
    when(mockRepository.sendMessage(question, userId: 1))
        .thenThrow(Exception('Network error'));

    // Act
    await provider.sendMessage(question);

    // Assert
    expect(provider.messages.length, 3); // welcome + user + error
    expect(provider.messages[2].isError, true);
    expect(provider.error, isNotNull);
    expect(provider.isLoading, false);
  });

  test('clearConversation should reset messages', () {
    // Act
    provider.clearConversation();

    // Assert
    expect(provider.messages.length, 1);
    expect(provider.messages[0].content, startsWith('👋 Bonjour !'));
  });
}