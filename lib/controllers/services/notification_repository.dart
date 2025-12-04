import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/notification_item.dart';

class NotificationRepository {
  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<NotificationItem>> watchNotifications(String userId) {
    final query = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50);

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs
            .map(
              (doc) => NotificationItem.fromMap(
                doc.id,
                doc.data(),
                defaultCreatedAt: doc.data()['createdAt'] is Timestamp
                    ? (doc.data()['createdAt'] as Timestamp).toDate()
                    : null,
              ),
            )
            .toList();
      },
    );
  }

  Future<void> markAllRead(String userId) async {
    final batch = _firestore.batch();
    final unreadSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('status', isEqualTo: NotificationStatus.unread.name)
        .get();

    for (final doc in unreadSnapshot.docs) {
      batch.update(doc.reference, {
        'status': NotificationStatus.read.name,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> markRead(String userId, String notificationId) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId);

    await docRef.update({
      'status': NotificationStatus.read.name,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes all notifications that are already marked as read for the user.
  Future<void> clearRead(String userId) async {
    const pageSize = 50;
    while (true) {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('status', isEqualTo: NotificationStatus.read.name)
          .limit(pageSize)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // If we got fewer than pageSize, we're done.
      if (snapshot.docs.length < pageSize) return;
    }
  }
}


