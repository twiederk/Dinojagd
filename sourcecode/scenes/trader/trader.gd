class_name Trader
extends StaticBody2D

signal trading_started
signal trading_ended


func _on_trading_area_body_entered(body):
	if body is Player:
		trading_started.emit()


func _on_trading_area_body_exited(body):
	if body is Player:
		trading_ended.emit()
