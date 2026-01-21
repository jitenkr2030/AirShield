import tensorflow as tf
import numpy as np
import logging
from typing import Dict, Any, Optional
from datetime import datetime
import pickle

from app.core.config import settings

logger = logging.getLogger(__name__)

class MLService:
    """Machine Learning service for air quality predictions and image analysis"""
    
    def __init__(self):
        self.image_model: Optional[tf.lite.Interpreter] = None
        self.prediction_model: Optional[Any] = None
        self.models_loaded = False
    
    async def initialize(self):
        """Initialize ML models"""
        try:
            await self._load_models()
            self.models_loaded = True
            logger.info("ML service initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize ML service: {e}")
            self.models_loaded = False
    
    async def shutdown(self):
        """Shutdown ML service"""
        logger.info("ML service shutdown complete")
    
    async def _load_models(self):
        """Load TensorFlow Lite models"""
        try:
            # Load image-to-PM2.5 model
            if tf.io.gfile.exists(settings.IMAGE_MODEL_PATH):
                self.image_model = tf.lite.Interpreter(model_path=settings.IMAGE_MODEL_PATH)
                self.image_model.allocate_tensors()
                logger.info("Image-to-PM2.5 model loaded successfully")
            else:
                logger.warning(f"Image model not found at {settings.IMAGE_MODEL_PATH}")
            
            # Load prediction model
            if tf.io.gfile.exists(settings.PREDICTION_MODEL_PATH):
                with open(settings.PREDICTION_MODEL_PATH, 'rb') as f:
                    self.prediction_model = pickle.load(f)
                logger.info("Prediction model loaded successfully")
            else:
                logger.warning(f"Prediction model not found at {settings.PREDICTION_MODEL_PATH}")
                
        except Exception as e:
            logger.error(f"Error loading ML models: {e}")
    
    async def predict_pm25_from_image(self, image_data: bytes) -> Dict[str, Any]:
        """Predict PM2.5 concentration from image"""
        if not self.image_model:
            raise ValueError("Image model not loaded")
        
        try:
            # Preprocess image
            input_details = self.image_model.get_input_details()
            output_details = self.image_model.get_output_details()
            
            # Convert image bytes to numpy array and preprocess
            # This is a simplified version - actual implementation would depend on model requirements
            processed_image = self._preprocess_image(image_data)
            
            # Make prediction
            self.image_model.set_tensor(input_details[0]['index'], processed_image)
            self.image_model.invoke()
            
            # Get prediction
            prediction = self.image_model.get_tensor(output_details[0]['index'])
            confidence = self._calculate_confidence(prediction)
            
            return {
                "predicted_pm25": float(prediction[0][0]) if len(prediction.shape) > 1 else float(prediction[0]),
                "confidence_score": confidence,
                "model_version": "1.0.0",
                "prediction_time": datetime.utcnow()
            }
            
        except Exception as e:
            logger.error(f"Error in image prediction: {e}")
            return {
                "predicted_pm25": None,
                "confidence_score": 0.0,
                "error": str(e)
            }
    
    async def predict_pollution_levels(self, features: Dict[str, Any]) -> Dict[str, Any]:
        """Predict pollution levels using ML models"""
        if not self.prediction_model:
            # Fallback to rule-based prediction
            return self._rule_based_prediction(features)
        
        try:
            # Prepare features for prediction
            prediction_features = self._prepare_prediction_features(features)
            
            # Make prediction
            prediction = self.prediction_model.predict(prediction_features)
            
            # Process prediction results
            if hasattr(prediction, 'predict_proba'):
                # Classification model
                probabilities = prediction.predict_proba(prediction_features)[0]
                predicted_class = prediction.predict(prediction_features)[0]
                confidence = float(max(probabilities))
            else:
                # Regression model
                predicted_value = prediction.predict(prediction_features)[0]
                confidence = 0.8  # Default confidence for regression
                predicted_class = predicted_value
            
            return {
                "predicted_aqi": int(predicted_class) if isinstance(predicted_class, (int, float)) else 50,
                "confidence_score": confidence,
                "model_type": "ml",
                "prediction_time": datetime.utcnow()
            }
            
        except Exception as e:
            logger.error(f"Error in pollution prediction: {e}")
            return self._rule_based_prediction(features)
    
    def _preprocess_image(self, image_data: bytes) -> np.ndarray:
        """Preprocess image for model input"""
        # This would implement actual image preprocessing
        # For now, return a dummy array
        image_array = np.frombuffer(image_data, dtype=np.uint8)
        image_array = image_array.reshape(1, 224, 224, 3)  # Adjust based on model input shape
        return image_array.astype(np.float32) / 255.0
    
    def _calculate_confidence(self, prediction: np.ndarray) -> float:
        """Calculate prediction confidence score"""
        # Simplified confidence calculation
        if len(prediction.shape) == 1:
            return 0.8  # Default confidence
        else:
            max_prob = np.max(prediction)
            return float(max_prob)
    
    def _prepare_prediction_features(self, features: Dict[str, Any]) -> np.ndarray:
        """Prepare features for prediction model"""
        # Extract relevant features
        feature_values = [
            features.get('temperature', 20.0),
            features.get('humidity', 50.0),
            features.get('pressure', 1013.0),
            features.get('wind_speed', 2.0),
            features.get('hour', datetime.utcnow().hour),
            features.get('day_of_week', datetime.utcnow().weekday()),
        ]
        
        return np.array([feature_values])
    
    def _rule_based_prediction(self, features: Dict[str, Any]) -> Dict[str, Any]:
        """Fallback rule-based prediction"""
        try:
            # Simple rule-based prediction
            base_aqi = 50
            
            # Temperature effect
            temp = features.get('temperature', 20.0)
            if temp > 30:
                base_aqi += 20
            elif temp < 0:
                base_aqi += 10
            
            # Humidity effect
            humidity = features.get('humidity', 50.0)
            if humidity > 80:
                base_aqi += 15
            elif humidity < 30:
                base_aqi += 10
            
            # Wind speed effect
            wind_speed = features.get('wind_speed', 2.0)
            if wind_speed < 1:
                base_aqi += 20
            elif wind_speed > 10:
                base_aqi -= 15
            
            # Time of day effect
            hour = features.get('hour', datetime.utcnow().hour)
            if 7 <= hour <= 9 or 17 <= hour <= 19:  # Rush hours
                base_aqi += 25
            elif 22 <= hour or hour <= 6:  # Night time
                base_aqi -= 10
            
            # Ensure AQI is within bounds
            predicted_aqi = max(0, min(500, base_aqi))
            
            return {
                "predicted_aqi": int(predicted_aqi),
                "confidence_score": 0.6,  # Lower confidence for rule-based
                "model_type": "rule_based",
                "prediction_time": datetime.utcnow()
            }
            
        except Exception as e:
            logger.error(f"Error in rule-based prediction: {e}")
            return {
                "predicted_aqi": 50,
                "confidence_score": 0.3,
                "model_type": "fallback",
                "prediction_time": datetime.utcnow()
            }
    
    async def validate_prediction(self, prediction: Dict[str, Any], actual_reading: Dict[str, Any]) -> Dict[str, Any]:
        """Validate prediction against actual readings"""
        try:
            predicted_aqi = prediction.get("predicted_aqi", 50)
            actual_aqi = actual_reading.get("aqi", 50)
            
            # Calculate prediction error
            error = abs(predicted_aqi - actual_aqi)
            accuracy = max(0, 1 - (error / 100))  # Normalize to 0-1 range
            
            return {
                "prediction_id": prediction.get("id"),
                "predicted_aqi": predicted_aqi,
                "actual_aqi": actual_aqi,
                "error": error,
                "accuracy": accuracy,
                "validation_time": datetime.utcnow()
            }
            
        except Exception as e:
            logger.error(f"Error validating prediction: {e}")
            return {"error": str(e)}
    
    async def retrain_model(self, training_data: list) -> Dict[str, Any]:
        """Retrain model with new data (placeholder)"""
        try:
            # This would implement actual model retraining
            # For now, just log the request
            logger.info(f"Model retraining requested with {len(training_data)} samples")
            
            return {
                "status": "training_initiated",
                "samples_count": len(training_data),
                "estimated_completion": datetime.utcnow() + timedelta(hours=1)
            }
            
        except Exception as e:
            logger.error(f"Error initiating model retraining: {e}")
            return {"status": "error", "error": str(e)}